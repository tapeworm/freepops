-- ************************************************************************** --
--  FreePOPs @lycos.it webmail interface
--  
--  $Id$
--  
--  Released under the GNU/GPL license
--  Written by Enrico Tassi <gareuselesinge@users.sourceforge.net>
-- ************************************************************************** --

-- these are used in the init function
PLUGIN_VERSION = "0.0.1"
PLUGIN_NAME = "Lycos.IT"

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
local lycos_string = {
	-- The uri the browser uses when you click the "login" button
	login = "http://login.lycos.it/lsu/lsu_login.php",
	login_post= "membername=%s&password=%s&product=email&"..
		"service=lycos&redirect=http://mail.lycos.it/&"..
		"target_url=1&fail_url=&"..
		"format=&redir_fail=http://www.lycos.it/",
	login_failC="(Spiacente, ma questo Alias non esiste)",
	loginC = '<frame.*src="([^"]+)"',
	-- mesage list mlex
	statE = '.*<div class="whrnopadding">.*</div>.*<div>.*<div>[.*]{img}.*</div>.*<div>.*</div>.*<div>.*</div>.*<div>[.*]{img}.*</div>.*<div class="w15L">.*<input.*name.*CHECK_>.*</div>.*</div>',
	statG = 'O<O>O<O>O<O>O<O>[O]{O}O<O>O<O>O<O>O<O>O<O>O<O>[O]{O}X<O>O<O>O<X>O<O>O<O>',
	-- The uri for the first page with the list of messages
	first = "http://mail.lycos.it/Europe/Bin/Mail/Features/FolderContent/folderContent.jsp?FOLDERID=5&",
	-- The uri to get the next page of messages
	nextC ='<a href="(?FOLDERID=5&MYNEXT=%d+&MYSORT=%-1)">Successivo</a>',
	next = "http://mail.lycos.it/Europe/Bin/Mail/Features/FolderContent/folderContent.jsp",

	-- The capture to understand if the session ended
	timeoutC = '(FIXME)',
	-- The uri to save a message (read download the message)
	save = "http://mail.lycos.it/Europe/Bin/Mail/Features/MailContent/mailContent.jsp?MESSAGEID=%d&PARENTID=5&MYSORT=-1",
	-- The uri to delete some messages
	delete = "http://mail.lycos.it/Europe/Bin/Mail/Features/FolderContent/actionFolderContent.jsp",
	delete_post = "ACTION=3&",
	-- The peace of uri you must append to delete to choose the messages 
	-- to delete
	delete_next = "CHECK_%d=1&"
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
	login_url = nil,
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
function lycos_login()
	if internal_state.login_done then
		return POPSERVER_ERR_OK
	end

	-- build the uri
	local password = internal_state.password
	local domain = internal_state.domain
	local username = internal_state.name
	local uri = lycos_string.login
	local post = string.format(lycos_string.login_post,username,password)
	
	-- the browser must be preserved
	internal_state.b = browser.new()

	local b = internal_state.b

	b.curl:setopt(curl.OPT_VERBOSE,1)

	local extract_f = support.do_extract(
		internal_state,"login_url",lycos_string.loginC)
	local check_f = support.check_fail
	local retrive_f = support.retry_n(
		3,support.do_post(internal_state.b,uri,post))

	if not support.do_until(retrive_f,check_f,extract_f) then
		log.error_print("Login failed\n")
		return POPSERVER_ERR_AUTH
	end

	if internal_state.login_url == nil then
		log.error_print("unable to get the loginC")
		return POPSERVER_ERR_AUTH
	end

	local uri = "http://mail.lycos.it" .. internal_state.login_url

	local body,err = b:get_uri(uri)

	if body == nil then
		log.error_print("login falied, unable to get the mail site")
		return POPSERVER_ERR_AUTH
	end

	-- save all the computed data
	internal_state.login_done = true
	
	-- log the creation of a session
	log.say("Session started for " .. internal_state.name .. "@" .. 
		internal_state.domain .. "\n")

	return POPSERVER_ERR_OK
end

--------------------------------------------------------------------------------
-- The callbach factory for retr
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
		print("GOT:",len)
		if purge == true then
			--print("purging: "..string.len(s))
			return len,nil
		end
			
		s=global.a:tophack(s,global.lines_requested)
		s =  global.a:dothack(s).."\0"
			
		popserver_callback(s,data)

		global.bytes = global.bytes + len

		-- check if we need to stop (in top only)
		if global.a:check_stop(global.lines_requested) then
			purge = true
			global.lines = -1
			-- trucate it!
			return 0,nil
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
	local domain = freepops.get_domain(username)
	local name = freepops.get_name(username)

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
			return lycos_login()
		end
		
		-- exec the code loaded from the session tring
		c()

		log.say("Session loaded for " .. internal_state.name .. "@" .. 
			internal_state.domain .. "\n")
		
		return POPSERVER_ERR_OK
	else
		-- call the login procedure 
		return lycos_login()
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
	local b = internal_state.b
	local uri = string.format(lycos_string.delete)
	local post = string.format(lycos_string.delete_post)

	-- here we need the stat, we build the uri and we check if we 
	-- need to delete something
	local delete_something = false;
	
	for i=1,get_popstate_nummesg(pstate) do
		if get_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE) then
			post = post .. string.format(lycos_string.delete_next,
				get_mailmessage_uidl(pstate,i))
			delete_something = true	
		end
	end

	if delete_something then
		-- Build the functions for do_until
		local extract_f = function(s) return true,nil end
		local check_f = support.check_fail
		local retrive_f = support.retry_n(3,support.do_post(b,uri,post))

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
		internal_state.domain .. "\n")

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
	local b = internal_state.b

	-- this string will contain the uri to get. it may be updated by 
	-- the check_f function, see later
	local uri = lycos_string.first
	
	-- The action for do_until
	--
	-- uses mlex to extract all the messages uidl and size
	local function action_f (s) 
		-- calls match on the page s, with the mlexpressions
		-- statE and statG
		local x = mlex.match(s,lycos_string.statE,lycos_string.statG)

		--x:print()

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
			local uidl = x:get (1,i-1) 
			local size = x:get (0,i-1)

			-- arrange message size
			local k = nil
			_,_,k = string.find(size,"([Kk][Bb])")
			_,_,m = string.find(size,"([Mm][Bb])")
			_,_,size = string.find(size,"([%.%d]+)")
			_,_,uidl = string.find(uidl,'CHECK_([%d]+)')

			if not uidl or not size then
				return nil,"Unable to parse page"
			end

			-- arrange size
			size = tonumber(size)
			if k ~= nil then
				size = size * 1024
			elseif m ~= nil then
				size = size * 1024 * 1024
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
		local _,_,nex = string.find(s,lycos_string.nextC)
		if nex ~= nil then
			uri = lycos_string.next .. nex
			-- continue the loop
			return false
		else
			return true
		end
	end

	-- this is simple and uri-dependent
	local function retrive_f ()  
		print("getting "..uri)
		local f,err = b:get_uri(uri)
		if f == nil then
			return f,err
		end

		--print("received:",f)
		local g = io.open("out.html","w")
		g:write(f)
		g:close()
		
	--	
	--	local _,_,c = string.find(f,tin_string.timeoutC)
	--	if c ~= nil then
	--		internal_state.login_done = nil
	--		session.remove(key())

	--		local rc = lycos_login()
	--		if rc ~= POPSERVER_ERR_OK then
	--			return nil,"Session ended,unable to recover"
	--		end
	--		
	--		session_id = internal_state.session_id
	--		b = internal_state.b
	--		-- popserver has not changed
	--		
	--		uri = string.format(tin_string.first,popserver,
	--			session_id,curl.escape(pop_login))
	--		return b:get_uri(uri)
	--	end
	--	
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
	
	-- some local stuff
	local b = internal_state.b
	
	-- build the uri
	local uidl = get_mailmessage_uidl(pstate,msg)
	local uri = string.format(lycos_string.save,uidl)
	
	-- tell the browser to pipe the uri using cb
	--local f,rc = b:pipe_uri(uri,cb)

	--if not f then
	--	log.error_print("Asking for "..uri.."\n")
	--	log.error_print(rc.."\n")
	--	return POPSERVER_ERR_NETWORK
	--end
	--
	--local f,err = b:get_uri(uri)
	--popserver_callback(f.."\0" , data)

--	mimer.pipe_msg(
--		"headers\r\n","body",
--		{["attila.png"]="http://attila/images/attila.png"},
--		b,
--		function(s)popserver_callback(s,data)end)

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
	local session_id = internal_state.session_id
	local b = internal_state.b
	local popserver = b:wherearewe()
	local domain = internal_state.domain
	local user = internal_state.name
	local pop_login = user .. "@" .. domain

	-- build the uri
	local uidl = get_mailmessage_uidl(pstate,msg)
	local uri = string.format(tin_string.save,popserver,
				session_id,curl.escape(pop_login),uidl)

	-- build the callbacks --
	
	-- this data structure is shared between callbacks
	local global = {
		-- the current amount of lines to go!
		lines = lines, 
		-- the original amount of lines requested
		lines_requested = lines, 
		-- how many bytes we have received
		bytes = 0,
		total_bytes = get_mailmessage_size(pstate,msg),
		-- the stringhack (must survive the callback, since the 
		-- callback doesn't know when it must be destroyed)
		a = stringhack.new(),
		-- the first byte
		from = 0,
		-- the last byte
		to = 0,
		-- the minimum amount of bytes we receive 
		-- (compensates the mail header usually)
		base = 2,--2048,
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
		return global.lines < 0 or global.bytes >= global.total_bytes
	end
	-- nothing to do
	local action_f = function(_)
		return true
	end

	-- go!
	support.do_until(retrive_f,check_f,action_f)
	if not support.do_until(retrive_f,check_f,action_f) then
		if global.lines ~= -1 then
			log.error_print("Top failed\n")
			session.remove(key())
			return POPSERVER_ERR_UNKNOWN
		end
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
	
	-- the MIME mail generator module
	if freepops.dofile("mimer.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end	
	
	return POPSERVER_ERR_OK
end

-- EOF
-- ************************************************************************** --
