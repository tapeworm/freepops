-- ************************************************************************** --
--  FreePOPs pop3 forwarding plugin
-- 
--  $Id$
-- 
--  Released under the GNU/GPL license
--  Written by Enrico Tassi <gareuselesinge@users.sourceforge.net>
-- ************************************************************************** --

-- ************************************************************************** --
-- WARNING        the bindings for psock in lua are really poor       WARNING --
-- ************************************************************************** --

PLUGIN_VERSION = "0.0.1"
PLUGIN_NAME = "POPforward"

-- ************************************************************************** --
--  State
-- ************************************************************************** --

pf_state = {
	socket = nil,
}

-- Is called to initialize the module
function init(pstate)
	log.dbg("FreePOPs plugin '"..
		PLUGIN_NAME.."' version '"..PLUGIN_VERSION.."' started!\n")
		
	freepops.export(pop3server)
	
	-- checks on globals
	freepops.set_sanity_checks()

	return POPSERVER_ERR_OK
end

function single_line(cmd,f)
	local l = pf_state.socket:send(cmd)
	
	if l < 0 then 
		log.error_print("Short send of "..l..
			" instead of "..string.len(cmd).."\n")
		return POPSERVER_ERR_NETWORK 
	end

	local l = pf_state.socket:recv()
	if not (string.find(l,"^+OK")) then 
		log.error_print(l)
		return POPSERVER_ERR_UNKNOWN 
	end

	if f then
		return f(l)
	else
		return POPSERVER_ERR_OK
	end
end

function do_pipe(pdata)
	return function(s)
	local l,err,time = nil,nil,nil
	
	while l ~= "." do
		l = pf_state.socket:recv()
		if not l then 
			log.error_print("ERROR??")
			return POPSERVER_ERR_NETWORK 
		end
		
		if l ~= "." then
			popserver_callback(l.."\r\n",pdata)
		end
	end
	return POPSERVER_ERR_OK
	end
end

function do_repeat(f)
	return function(s)
	local l = nil
	
	while l ~= "." do
		l = pf_state.socket:recv()
		if not l then 
			log.error_print("ERROR?")
			return POPSERVER_ERR_NETWORK 
		end
		
		if l ~= "." then
			f(l)
		end
	end
	return POPSERVER_ERR_OK
	end
end


-- Must save the mailbox name
function user(pstate,username)
	local l,err,time = nil,nil,nil
	pf_state.socket = psock.connect(freepops.MODULE_ARGS.host,
		freepops.MODULE_ARGS.port)
	if not pf_state.socket then
		log.error_print("unable to connect")
		return POPSERVER_ERR_NETWORK
	end
	
	l = pf_state.socket:recv()
	if not l then
		log.error_print(err)
		return POPSERVER_ERR_NETWORK
	end
	
	return single_line("USER "..
		freepops.MODULE_ARGS.realusername or username,nil)
end

-- Must login
function pass(pstate,password)
	return single_line("PASS "..password,nil)
end

-- Must quit without updating
function quit(pstate)
	local rc = single_line("QUIT",nil)
	return rc
end

-- Update the mailbox status and quit
function quit_update(pstate)
	return quit(pstate)
end

-- Fill the number of messages and their size
function stat(pstate)
	local f = function(l)
		for n,s in string.gfind(l,"+OK (%d+) (%d+)") do
			set_popstate_nummesg(pstate,n)
			set_popstate_boxsize(pstate,s)
			return POPSERVER_ERR_OK
		end
		log.dbg("Ubale to find +OK in "..l.."\n")
		return POPSERVER_ERR_UNKNOWN
	end

	return single_line("STAT\r\n",f)
end

-- Fill msg uidl field
function uidl(pstate,msg)
	local f = function(l)
		for n,u in string.gfind(l,"+OK (%d+) (%d+)") do
			set_mailmessage_uidl(pstate,n,u)
			return POPSERVER_ERR_OK
		end
		return POPSERVER_ERR_UNKNOWN
	end

	return single_line("UIDL "..msg,f)
end

-- Fill all messages uidl field
function uidl_all(pstate)
	local f = do_repeat(function(l)
		for n,u in string.gfind(l,"(%d+) (%d+)") do
			set_mailmessage_uidl(pstate,n,u)
			print(l)
		end
		end)

	return single_line("UIDL",f)
end

-- Fill msg size
function list(pstate,msg)
	local f = function(l)
		for n,u in string.gfind(l,"+OK (%d+) (%d+)") do
			set_mailmessage_size(pstate,n,u)
			return POPSERVER_ERR_OK
		end
		return POPSERVER_ERR_UNKNOWN
	end

	return single_line("LIST "..msg,f)
end

-- Fill all messages size
function list_all(pstate)
	local f = do_repeat(function(l)
		for n,u in string.gfind(l,"(%d+) (%d+)") do
			set_mailmessage_size(pstate,n,u)
		end
		end)

	return single_line("LIST",f)
end

-- Unflag each message merked for deletion
function rset(pstate)
	return single_line("RSET",nil)
end

-- Mark msg for deletion
function dele(pstate,msg)
	return single_line("DELE "..msg,nil)
end

-- Do nothing
function noop(pstate)
	return single_line("NOOP",nil)
end

-- Get first lines message msg lines, must call 
-- popserver_callback to send the data
function top(pstate,msg,lines,pdata)
	return single_line("TOP "..msg.." "..lines,do_pipe(pdata))
end

-- Get message msg, must call 
-- popserver_callback to send the data
function retr(pstate,msg,pdata)
	return single_line("RETR "..msg,do_pipe(pdata))
end

-- EOF
-- ************************************************************************** --
