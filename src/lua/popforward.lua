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

PLUGIN_VERSION = "0.0.2"
PLUGIN_NAME = "POPforward"

-- ************************************************************************** --
--  State
-- ************************************************************************** --

pf_state = {
	socket = nil,
	pipe = nil,
	pipe_limit = 0,
	listed = false,
	stat_done = false,
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

	local l = pf_state.socket:recv() or "-ERR network error"
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
	local l = nil
	
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

local function pipe_split(s)
	if type(s) == "table" then
		return s
	elseif type(s) == "nil" then
		return nil
	else
		local t = {}
		for x in string.gfind(s,"([^ ]+)") do
			table.insert(t,x)
		end
		return t
	end
end

-- Must save the mailbox name
function user(pstate,username)

	pf_state.pipe = pipe_split(freepops.MODULE_ARGS.pipe)
	pf_state.pipe_limit = freepops.MODULE_ARGS.pipe_limit or 0
	pf_state.pipe_limit = tonumber(pf_state.pipe_limit)

	-- sanity checks
	if freepops.MODULE_ARGS.host == nil then
		log.error_print("host must be non null")
		return POPSERVER_ERR_AUTH
	end
	
	local _,_,host,port=string.find(freepops.MODULE_ARGS.host,"(.*):(%d+)")
	if host == nil then
		host = freepops.MODULE_ARGS.host
	end
	if port ~= nil and freepops.MODULE_ARGS.port ~= nil then
		log.error_print("you should use host:port or set "..
			"explicity the port, but not both")
		return POPSERVER_ERR_AUTH
	end
	if port == nil and freepops.MODULE_ARGS.port == nil then
		log.error_print("you should use host:port or set "..
			"explicity the port")
		return POPSERVER_ERR_AUTH
	end
	port = port or freepops.MODULE_ARGS.port

	--here we are
	pf_state.socket = psock.connect(host,port)
	if not pf_state.socket then
		log.error_print("unable to connect")
		return POPSERVER_ERR_NETWORK
	end
	
	local l = nil
	l = pf_state.socket:recv()
	if not l then
		log.error_print("Error receiving the welcome")
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


local function ensure_stat(pstate)
	if pf_state.stat_done then
		return POPSERVER_ERR_OK
	end

	return stat(pstate)
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

	pf_state.stat_done = true
	
	return single_line("STAT\r\n",f)
end

-- Fill msg uidl field
function uidl(pstate,msg)
	local rc = ensure_stat(pstate) 
	if rc ~= POPSERVER_ERR_OK then return rc end
	
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
	local rc = ensure_stat(pstate) 
	if rc ~= POPSERVER_ERR_OK then return rc end

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
	local rc = ensure_stat(pstate) 
	if rc ~= POPSERVER_ERR_OK then return rc end

	local f = function(l)
		for n,u in string.gfind(l,"+OK (%d+) (%d+)") do
			set_mailmessage_size(pstate,n,u)
			return POPSERVER_ERR_OK
		end
		return POPSERVER_ERR_UNKNOWN
	end

	return single_line("LIST "..msg,f)
end

local function ensure_list_all(pstate)
	if pf_state.listed then
		return POPSERVER_ERR_OK
	end

	return list_all(pstate)
end

-- Fill all messages size
function list_all(pstate)
	local rc = ensure_stat(pstate) 
	if rc ~= POPSERVER_ERR_OK then return rc end

	local f = do_repeat(function(l)
		for n,u in string.gfind(l,"(%d+) (%d+)") do
			set_mailmessage_size(pstate,n,u)
		end
		end)

	pf_state.listed = true
		
	return single_line("LIST",f)
end

-- Unflag each message merked for deletion
function rset(pstate)
	local rc = ensure_stat(pstate) 
	if rc ~= POPSERVER_ERR_OK then return rc end

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
	if pf_state.pipe ~= nil then
		if pf_state.pipe_limit ~= 0 then
			ensure_list_all(pstate)
		end
		local size = get_mailmessage_size(pstate,msg)
		if pf_state.pipe_limit == 0 or size < pf_state.pipe_limit then
			local m = {}
			local f = do_repeat(function(l)
				table.insert(m,l)
			end)
			local rc = single_line("RETR "..msg,f)
			if rc ~= POPSERVER_ERR_OK then
				-- fixme
			end
			m = table.concat(m,"\r\n") .. "\r\n"
			local r,w = io.dpopen(unpack(pf_state.pipe))
			if r == nil or w == nil then
				--fixme
			end
			w:write(m)
			w:close()
			m = r:read("*a")
			r:close()
			popserver_callback(m,pdata)
			return POPSERVER_ERR_OK
		else
			return single_line("RETR "..msg,do_pipe(pdata))
		end
	else
		return single_line("RETR "..msg,do_pipe(pdata))
	end
end

-- EOF
-- ************************************************************************** --
