-- --------------------------- READ THIS PLEASE ----------------------------- --
-- This file is not only the libero webmail plugin. Is is also a well 
-- documented example of webmail plugin. 
--
-- Before reading this you should learn something about lua. The lua 
-- language is an excellen (at least in my opinion), small and easy 
-- language. You can learn something at http://www.lua.org (the main website)
-- or at http://lua-users.org/wiki/TutorialDirectory (a good and short tutorial)
--
-- Feel free to contact the author if you have problems in understanding 
-- this file
--
-- To start writing a new plugin please use skeleton.lua as the base.
-- -------------------------------------------------------------------------- --


-- ************************************************************************** --
--  FreePOPs @libero.it, @inwind.it, @blu.it, @iol.it webmail interface
--  
--  $Id$
--  
--  Released under the GNU/GPL license
--  Written by Enrico Tassi <gareuselesinge@users.sourceforge.net>
-- ************************************************************************** --

-- these are used in the init function
PLUGIN_VERSION = "0.0.2"
PLUGIN_NAME = "Libero.IT"

-- ************************************************************************** --
--  strings
-- ************************************************************************** --

-- this are the webmail-dependent strings
--
-- Some of them are incomplete, in the sense that are used as string.format()
-- (read sprintf) arguments, so theyr %s and %d are filled properly
-- 
-- C, E, G are postfix respectively to Captures (lua string pcre-style 
-- expressions), mlex expressions, mlex get expressions.
-- 
local libero_string = {
	-- The uri the browser uses when you click the "login" button
	login = "http://wpop%d%s/cgi-bin/webmail.cgi?dominio=%s&"..
		"LOGIN=%s&PASSWD=%s&choice=%s&Act_Login.x=%d&Act_Login.y=%d",
	-- This is the capture to get the session ID from the login-done webpage
	sessionC = "/cgi%-bin/webmail%.cgi%?ID=([a-zA-Z0-9_]+)&",
	-- This is the mlex expression to interpret the message list page.
	-- Read the mlex C module documentation to understand the meaning
	--
	-- This is probabli one of the more boaring tasks of the story.
	-- An easy and not so boaring way of writing a mlex expression is
	-- to cut and paste the html source and work on it. For example
	-- you could copy a message table row in a blank file, substitute
	-- every useless field with '.*'.
	statE = ".*<script>TREvidenceMsg</script>.*<TD>.*<input.*value.*=.*[[:digit:]]+.*>.*</TD>.*<TD>.*<IMG>.*</TD>.*<TD>.*<IMG>.*</TD>.*<TD>.*<IMG>.*</TD>.*<TD>.*<img>.*</TD>.*<TD>.*<IMG>.*</TD>.*<TD>.*<a>.*<script>IMGEvidenceMsg</script>.*</a>.*<script>AEvidenceMsg</script>[.*]{b}.*{/b}[.*]</a>.*</TD>.*<TD>.*<IMG>.*</TD>.*<TD>.*<script>AEvidenceMsg</script>[.*]{b}.*{/b}[.*]</a>.*</TD>.*<TD>.*<IMG>.*</TD>.*<script>TDEvidenceMsg</script>.*</TD>.*<TD>.*<IMG>.*</TD>.*<script>TDEvidenceMsg</script>[.*]{b}.*[[:digit:]]+.*{/b}[.*]</TD>.*</TR>",
	-- This is the mlex get expression to choose the important fields 
	-- of the message list page. Used in combination with statE
	statG = "O<O><O>O<O>O<X>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O><O>O<O>O<O><O>[O]{O}O{O}[O]<O>O<O>O<O>O<O>O<O>O<O>O<O><O>[O]{O}O{O}[O]<O>O<O>O<O>O<O>O<O>O<O><O>O<O>O<O>O<O>O<O>O<O><O>[O]{O}X{O}[O]<O>O<O>",
	-- The uri for the first page with the list of messages
	first = "http://%s/cgi-bin/webmail.cgi?ID=%s&Act_Msgs=1&"..
		"C_Folder=aW5ib3g%%3D",
	-- The capture to check if there is one more page of message list
	next_checkC = "<a href=\"javascript:doit"..
		"%('Act_Msgs_Page_Next',1,1%)\">.*</a>",
	-- The uri to get the next page of messages
	next = "http://%s/cgi-bin/webmail.cgi?ID=%s&Act_Msgs_Page_Next=1&"..
		"HELP_ID=inbox&SEL_ALL=0&"..
		"From_Vu=1&C_Folder=aW5ib3g%%3D&msgID=&Msg_Read=&"..
		"R_Folder=&ZONEID=&Fld_P_List=aW5ib3g%%3D&"..
		"dummy1_List=aW5ib3g%%3D&dummy2_List=aW5ib3g%%3D",
	-- The capture to understand if the session ended
	timeoutC = "(Sessione non valida. Riconnettersi)",
	-- The uri to save a message (read download the message)
	save = "http://%s/cgi-bin/webmail.cgi/message.txt?ID=%s&"..
		"msgID=%s&Act_V_Save=1&"..
		"R_Folder=aW5ib3g=&Body=0&filename=message.txt",
	-- The uri to delete some messages
	delete = "http://%s/cgi-bin/webmail.cgi?ID=%s&Act_Msgs_Del_CF_Ok=1&"..
		"HELP_ID=inbox&SEL_ALL=0&From_Vu=1&C_Folder=SU5CT1g%%3D&"..
		"msgID=&Msg_Read=&R_Folder=&ZONEID=&Fld_P_List=aW5ib3g%%3D&"..
		"dummy1_List=aW5ib3g%%3D&dummy2_List=aW5ib3g%%3D&Msg_Nb=%d",
	-- The peace of uri you must append to delete to choose the messages 
	-- to delete
	delete_next = "&Msg_Sel_%d=%s"
}

-- this table contains the realtion between the mail address domain, the
-- webmail domain name and the mailbox domain
local libero_domain = {
	["libero.it"] = { website=".libero.it",        choice="libero" },
	["inwind.it"] = { website=".inwind.libero.it", choice="inwind" },
	["iol.it"]    = { website=".iol.libero.it",    choice="iol"    },
	["blu.it"]    = { website=".blu.libero.it",    choice="blu"    }
}

-- ************************************************************************** --
--  State
-- ************************************************************************** --

-- this is the internal state of the plugin. This structure will be serialized 
-- and saved to remember the state.
internal_state = {
	stat_done = false,
	login_done = false,
	popserver = nil,
	session_id = nil,
	domain = nil,
	name = nil,
	password = nil,
	b = nil
}

-- ************************************************************************** --
--  Helpers functions
-- ************************************************************************** --

--------------------------------------------------------------------------------
-- Checks if a message number is in range
--
function check_range(pstate,msg)
	local n = get_popstate_nummesg(pstate)
	return msg >= 1 and msg <= n
end

--------------------------------------------------------------------------------
-- Extracts the domain name of a mailaddress
--
function get_domain(s)
	local _,_,d = string.find(s,"[_%.%a%d]+@([_%.%a%d]+)")
	return d
end

--------------------------------------------------------------------------------
-- Extracts the account name of a mailaddress
--
function get_name(s)
	local _,_,d = string.find(s,"([_%.%a%d]+)@[_%.%a%d]+")
	return d
end

--------------------------------------------------------------------------------
-- Checks the validity of a domain
--
function check_domain(domain)
	return 	libero_domain[domain] ~= nil
end

--------------------------------------------------------------------------------
-- Serialize the internal_state
--
-- serial. serialize is not enough powerfull to correcly serialize the 
-- internal state. the problem is the field b. b is an object. this means
-- that is a table (and no problem for this) that has some field that are
-- pointers to functions. this is the problem. there is no easy way for the 
-- serial module to know how to serialize this. so we call b:serialize 
-- method by hand hacking a bit on names
--
function serialize_state()
	internal_state.stat_done = false;
	
	return serial.serialize("internal_state",internal_state) ..
		internal_state.b:serialize("internal_state.b")
end

--------------------------------------------------------------------------------
-- The key used to store session info
--
-- Ths key must be unique for all webmails, since the session pool is one 
-- for all the webmails
--
function key()
	return (internal_state.name or "")..
		(internal_state.domain or "")..
		(internal_state.password or "")
end

--------------------------------------------------------------------------------
-- Login to the libero website
--
function libero_login()
	if internal_state.login_done then
		return POPSERVER_ERR_OK
	end

	-- build the uri
	local password = internal_state.password
	local popnumber = math.mod(os.time(),16) + 1
	local domain = internal_state.domain
	local site = libero_domain[domain].website
	local choice = libero_domain[domain].choice
	local user = internal_state.name
	if internal_state.domain ~= "libero.it" then
		user = user .. "@" .. domain
	end
	local x,y = math.mod(os.time(),16),math.mod(os.time()*2,16)
	local uri = string.format(libero_string.login,
		popnumber,site,domain,user,password,choice,x,y)
	
	-- the browser must be preserved
	internal_state.b = browser.new()
	
	-- the functions for do_until
	-- extract_f uses the support function to extract a capture specifyed 
	--   in libero_string.sessionC, and pu ts the result in 
	--   internal_state["session_id"]
	-- check_f the is the failure funtion, that means that the do_until
	--   will not repeat
	-- retrive_f is the function that do_retrive the uri uri with the
	--   browser b. The function will be retry_n 3 times if it fails
	local extract_f = support.do_extract(
		internal_state,"session_id",libero_string.sessionC)
	local check_f = support.check_fail
	local retrive_f = support.retry_n(
		3,support.do_retrive(internal_state.b,uri))

	-- maybe implement a do_once
	if not support.do_until(retrive_f,check_f,extract_f) then
		-- not sure that it is a password error, maybe a network error
		-- the do_until will log more about the error before us...
		-- maybe we coud add a sanity_check function to do until to
		-- check if the received page is a server error page or a 
		-- good page.
		log.error_print("Login failed\n")
		return POPSERVER_ERR_AUTH
	end

	-- check if do_extract has correctly extracted the session ID
	if internal_state.session_id == nil then
		log.error_print("Login failed, unable to get session ID\n")
		return POPSERVER_ERR_AUTH
	end
		
	-- save all the computed data
	internal_state.popserver = "wpop" .. popnumber .. site
	internal_state.login_done = true
	
	-- log the creation of a session
	log.say("Session started for " .. internal_state.name .. "@" .. 
		internal_state.domain .. 
		"(" .. internal_state.session_id .. ")\n")

	return POPSERVER_ERR_OK
end

--------------------------------------------------------------------------------
-- The callbach factory for retr
--
-- A callback factory is a function that generates other functions. both retr
-- and top need a callback. the callback is called when there is some data 
-- to send to the client. this is done with popserver_callback(s,data) 
-- where s is the data and data is the opaque data that is passed to to 
-- the retr/top function and is used internally by the popserve callbak. 
-- no need to know what it is, but we have to pass it. 
--
-- The callback function must accept 2 args: the data to send and an optional 
-- error message. it the data s is nil it means the err contains the 
-- relative error message. If s is "" it means that the trasmission 
-- ended sucesfully (read: the socket has benn closed correclty). 
-- 
-- Here a is an opaque data structure used by the
-- stringhack module. the stringhack module implements some usefull string 
-- manipulation tasks. 
-- tophack keeps track of how many lines have been 
-- processed. If more that lines (we talk of lines of mail body) have 
-- been processed the returned string will be trucated to the 
-- correct line number. 
-- dothack simply does a 'sed s/^\.$/../' but is really hard if the data 
-- is not divided in lines as in our case (ip packets are not line oriented),
-- so it is implemented in C for you. check_stop checks if the lines 
-- amount of lines have already been processed.
--
function retr_cb(data)
	local a = stringhack.new()
	
	return function(s,len)
		s = a:dothack(s).."\0"
			
		popserver_callback(s,data)
			
		return len,nil
	end
end

-- -------------------------------------------------------------------------- --
-- The callback for top is really similar to the retr, but checks for purging
-- unwanted data and sets globals.lines to -1 if no more lines are needed
--
function top_cb(global,data)
	local purge = false
	
	return function(s,len)
		if purge == true then
			--print("purging: "..string.len(s))
			return len,nil
		end
			
		s=global.a:tophack(s,global.lines_requested)
		s =  global.a:dothack(s).."\0"
			
		popserver_callback(s,data)

		-- check if we need to stop (in top only)
		if global.a:check_stop(global.lines_requested) then
			--print("TOP more than needed")
			purge = true
			global.lines = -1
			return len,nil
		else
			global.lines = global.lines_requested - 
				global.a:current_lines()
			return len,nil
		end
	end
end

-- ************************************************************************** --
--  Libero functions
-- ************************************************************************** --

-- Must save the mailbox name
function user(pstate,username)
	
	-- extract and check domain
	local domain = get_domain(username)
	local name = get_name(username)

	-- default is @libero.it (probably useless)
	if not domain then
		-- default domain
		domain = "libero.it"
	end

	-- check if the domain is valid
	if not check_domain(domain) then
		-- dead code
		return POPSERVER_ERR_AUTH
	end
	
	-- save domain and name
	internal_state.domain = domain
	internal_state.name = name
	
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Must login
function pass(pstate,password)
	-- save the password
	internal_state.password = password

	-- eventually load session
	local s = session.load_lock(key())

 	-- check if loaded properly
	if s ~= nil then
		-- "\a" means locked
		if s == "\a" then
			log.say("Session for "..internal_state.name..
				" is already locked\n")
			return POPSERVER_ERR_LOCKED
		end
	
		-- load the session
		local c,err = loadstring(s)
		if not c then
			log.error_print("Unable to load saved session: "..err)
			return libero_login()
		end
		
		-- exec the code loaded from the session tring
		c()

		log.say("Session loaded for " .. internal_state.name .. "@" .. 
			internal_state.domain .. 
			"(" .. internal_state.session_id .. ")\n")
		
		return POPSERVER_ERR_OK
	else
		-- call the login procedure 
		return libero_login()
	end
end

-- -------------------------------------------------------------------------- --
-- Must quit without updating
function quit(pstate)
	session.unlock(key())
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Update the mailbox status and quit
function quit_update(pstate)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end

	-- shorten names, not really important
	local popserver = internal_state.popserver
	local session_id = internal_state.session_id
	local b = internal_state.b

	local uri = string.format(libero_string.delete,popserver,session_id,
		get_popstate_nummesg(pstate))

	-- here we need the stat, we build the uri and we check if we 
	-- need to delete something
	local delete_something = false;
	
	for i=1,get_popstate_nummesg(pstate) do
		if get_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE) then
			uri = uri .. string.format(libero_string.delete_next,
				i,get_mailmessage_uidl(pstate,i))
			delete_something = true	
		end
	end

	if delete_something then
		-- Build the functions for do_until
		local extract_f = function(s) return true,nil end
		local check_f = support.check_fail
		local retrive_f = support.retry_n(3,support.do_retrive(b,uri))

		if not support.do_until(retrive_f,check_f,extract_f) then
			log.error_print("Unable to delete messages\n")
			return POPSERVER_ERR_UNKNOWN
		end
	end

	-- save fails if it is already saved
	session.save(key(),serialize_state(),session.OVERWRITE)
	-- unlock is useless if it have just been saved, but if we save 
	-- without overwriting the session must be unlocked manually 
	-- since it wuold fail instead overwriting
	session.unlock(key())

	log.say("Session saved for " .. internal_state.name .. "@" .. 
		internal_state.domain .. "(" .. 
		internal_state.session_id .. ")\n")

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Fill the number of messages and theyr size
function stat(pstate)

	-- check if already called
	if internal_state.stat_done then
		return POPSERVER_ERR_OK
	end
	
	-- shorten names, not really important
	local popserver = internal_state.popserver
	local session_id = internal_state.session_id
	local b = internal_state.b

	-- this string will contain the uri to get. it may be updated by 
	-- the check_f function, see later
	local uri = string.format(libero_string.first,popserver,session_id)

	-- The action for do_until
	--
	-- uses mlex to extract all the messages uidl and size
	local function action_f (s) 
		-- calls match on the page s, with the mlexpressions
		-- statE and statG
		local x = mlex.match(s,libero_string.statE,libero_string.statG)
		-- x:print()
		
		-- the number of results
		local n = x:count()

		if n == 0 then
			return true,nil
		end

		-- this is not really needed since the structure 
		-- grows automatically... maybe... don't remember now
		local nmesg_old = get_popstate_nummesg(pstate)
		local nmesg = nmesg_old + n
		set_popstate_nummesg(pstate,nmesg)

		-- gets all the results and puts them in the popstate structure
		for i = 1,n do
			local uidl = x:get (0,i-1) 
			local size = x:get (1,i-1)

			-- arrange message size
			local k = nil
			_,_,k = string.find(size,"([Kk][Bb])")
			_,_,size = string.find(size,"(%d+)")
			_,_,uidl = string.find(uidl,"value=\"(%d+)\"")
			size = tonumber(size) + 2
			if k ~= nil then
				size = size * 1024
			end

			if not uidl or not size then
				return nil,"Unable to parse page"
			end

			-- set it
			set_mailmessage_size(pstate,i+nmesg_old,size)
			set_mailmessage_uidl(pstate,i+nmesg_old,uidl)
		end
		
		return true,nil
	end

	-- check must control if we are not in the last page and 
	-- eventually change uri to tell retrive_f the next page to retrive
	local function check_f (s)  
		local tmp1,tmp2 = string.find(s,libero_string.next_checkC)
		if tmp1 ~= nil then
			-- change retrive behaviour
			uri = string.format(libero_string.next,
				popserver,session_id)
			-- continue the loop
			return false
		else
			return true
		end
	end

	-- this is simple and uri-dependent
	local function retrive_f ()  
		local f,err = b:get_uri(uri)
		if f == nil then
			return f,err
		end

		local _,_,c = string.find(f,libero_string.timeoutC)
		if c ~= nil then
			internal_state.login_done = nil
			session.remove(key())

			local rc = libero_login()
			if rc ~= POPSERVER_ERR_OK then
				return nil,--{
					--error=
					"Session ended,unable to recover"
					--} hope it is ok now
			end
			
			popserver = internal_state.popserver
			session_id = internal_state.session_id
			b = internal_state.b
			
			uri = string.format(libero_string.first,
				popserver,session_id)
			return b:get_uri(uri)
		end
		
		return f,err
	end

	-- this to initialize the data structure
	set_popstate_nummesg(pstate,0)

	-- do it
	if not support.do_until(retrive_f,check_f,action_f) then
		log.error_print("Stat failed\n")
		session.remove(key())
		return POPSERVER_ERR_UNKNOWN
	end

	-- save the computed values
	internal_state["stat_done"] = true
	
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Fill msg uidl field
function uidl(pstate,msg)
	return stat(pstate)
end

-- -------------------------------------------------------------------------- --
-- Fill all messages uidl field
function uidl_all(pstate)
	return stat(pstate)
end

-- -------------------------------------------------------------------------- --
-- Fill msg size
function list(pstate,msg)
	return stat(pstate)
end

-- -------------------------------------------------------------------------- --
-- Fill all messages size
function list_all(pstate,msg)
	return stat(pstate)
end

-- -------------------------------------------------------------------------- --
-- Do nothing
function noop(pstate)
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Unflag each message merked for deletion
function rset(pstate)
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end
	
	for i=1,get_popstate_nummesg(pstate) do
		unset_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE)
	end
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Mark msg for deletion
function dele(pstate,msg)
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end

	if not check_range(pstate,msg) then
		return POPSERVER_ERR_NOMSG
	end
	set_mailmessage_flag(pstate,msg,MAILMESSAGE_DELETE)
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Get first lines message msg lines, must call 
-- popserver_callback to send the data
function retr(pstate,msg,data)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end
	
	-- the callback
	local cb = retr_cb(data)
	
	-- some local stuff
	local popserver = internal_state.popserver
	local session_id = internal_state.session_id
	local b = internal_state.b
	
	-- build the uri
	local uidl = get_mailmessage_uidl(pstate,msg)
	local uri = string.format(libero_string.save,popserver,session_id,uidl)
	
	-- tell the browser to pipe the uri using cb
	local f,rc = b:pipe_uri(uri,cb)

	if not f then
		log.error_print("Asking for "..uri.."\n")
		log.error_print(rc.."\n")
		return POPSERVER_ERR_NETWORK
	end

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Get message msg, must call 
-- popserver_callback to send the data
function top(pstate,msg,lines,data)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end

	-- some local stuff
	local popserver = internal_state.popserver
	local session_id = internal_state.session_id
	local b = internal_state.b

	-- build the uri
	local uidl = get_mailmessage_uidl(pstate,msg)
	local uri = string.format(libero_string.save,popserver,session_id,uidl)

	-- build the callbacks --
	
	-- this data structure is shared between callbacks
	local global = {
		-- the current amount of lines to go!
		lines = lines, 
		-- the original amount of lines requested
		lines_requested = lines, 
		-- the stringhack (must survive the callback, since the 
		-- callback doesn't know when it must be destroyed)
		a = stringhack.new(),
		-- the first byte
		from = 0,
		-- the last byte
		to = 0,
		-- the minimum amount of bytes we receive 
		-- (compensates the mail header usually)
		base = 2048,
	}
	-- the callback for http stram
	local cb = top_cb(global,data)
	-- retrive must retrive from-to bytes, stores from and to in globals.
	local retrive_f = function()
		global.to = global.base + global.from + (global.lines + 1) * 100
		global.base = 0
		local extra_header = {
			"Range: bytes="..global.from.."-"..global.to
		}
		local f,err = b:pipe_uri(uri,cb,extra_header)
		global.from = global.to + 1
		--if f == nil --and rc.error == "EOF" 
		--	then
		--	return "",nil
		--end
		return f,err
	end
	-- global.lines = -1 means we are done!
	local check_f = function(_)
		return global.lines < 0
	end
	-- nothing to do
	local action_f = function(_)
		return true
	end

	-- go!
	if not support.do_until(retrive_f,check_f,action_f) then
		log.error_print("Top failed\n")
		session.remove(key())
		return POPSERVER_ERR_UNKNOWN
	end

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
--  This function is called to initialize the plugin.
--  Since we need to use the browser and save sessions we have to use
--  some modules with the dofile function
--
--  We also exports the pop3server.* names to global environment so we can
--  write POPSERVER_ERR_OK instead of pop3server.POPSERVER_ERR_OK.
--  
function init(pstate)
	freepops.export(pop3server)
	
	log.dbg("FreePOPs plugin '"..
		PLUGIN_NAME.."' version '"..PLUGIN_VERSION.."' started!\n")

	-- the serializatio module
	if freepops.dofile("serialize.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end 

	-- the browser module
	if freepops.dofile("browser.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end
		
	return POPSERVER_ERR_OK
end

-- EOF
-- ************************************************************************** --
