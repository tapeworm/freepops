-- ************************************************************************** --
--  FreePOPs @gmail.com webmail interface
--  
--  $Id$
--  
--  Released under the GNU/GPL license
--  Written by Rami Kattan <rkattan at gmail (single dot) com>
-- ************************************************************************** --

-- these are used in the init function
PLUGIN_VERSION = "0.0.2"
PLUGIN_NAME = "GMail.com"

-- ************************************************************************** --
--  strings
-- ************************************************************************** --

-- this are the webmail-dependent strings
--
-- Some of them are incomplete, in the sense that are used as string.format()
-- (read sprintf) arguments, so theyr %s and %d are filled properly
-- 
local gmail_string = {
	-- The uri the browser uses when you click the "login" button
	login = "https://www.google.com/accounts/ServiceLoginBoxAuth",
	login_post= "continue=https://gmail.google.com/gmail&service=mail&Email=%s&Passwd=%s&null=Sign in",
	login_checkcookie="https://www.google.com/accounts/CheckCookie?continue=http%3A%2F%2Fgmail.google.com%2Fgmail&service=mail&chtml=LoginDoneHtml",
	login_fail="Username and password do not match.",
	homepage="http://gmail.google.com/gmail",
	view_email="http://gmail.google.com/gmail?view=om&th=%s&zx=%s",
	-- message list (regexp)
	email_stat = ',%["(%w-)",(%d),(%d),".-","([^"]-)",.-%d%]\n',
	-- next 2 lines: link to view a message in html format, and regexp to extract sub messages.
	view_email_thread="http://gmail.google.com/gmail?view=cv&search=inbox&th=%s&zx=%s",
	email_stat_sub = '\nD%(%["mi",%d+,%d+,"(%w-)",(%d+),.-,".-","(.-)".-%]\n%);',
	-- This is the capture to get the session ID from the login-done webpage
	cookieVal = 'cookieVal= "(%w*-%w*)"',
	-- The uri for the first page with the list of messages
	first = "http://gmail.google.com/gmail?search=%s&view=tl&start=0&init=1&zx=%s",
	next_checkC = '\nD%(%["ts",(%d+),(%d+),(%d+),%d.-%]\n%);',
	next = "http://gmail.google.com/gmail?search=%s&view=tl&start=%s&init=1&zx=%s",
	-- view labels/folders = .../gmail?search=cat&cat=%s&view=tl&start=0&zx=%s
	delete = "http://gmail.google.com/gmail?search=inbox&view=tl&start=0",
	-- The peace of uri you must append to delete to choose the messages 
	-- to delete
	delete_post = "act=%s&at=%s",
	delete_next = "&t=%s"
}

-- ************************************************************************** --
--  State
-- ************************************************************************** --

-- this is the internal state of the plugin. This structure will be serialized 
-- and saved to remember the state.
internal_state = {
	stat_done = false,
	login_done = false,
	name = nil,
	password = nil,
	cmds = nil,
	b = nil,
	cookie_val = nil,
	cookie_sid = nil,
	gmail_at = ""
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
-- we don't want to break the webmail
--
function check_sanity(name,pass)
	if string.len(name) < 6 or string.len(name) > 30 then
		log.error_print("username must be from 6 to 30 chars")
		return false
	end
	local _,_,x = string.find(name,"([^0-9a-z%.%_%-])")
	if x ~= nil then
		log.error_print("username contains invalid character "..x.."\n")
		return false
	end	
	if string.len(pass) < 6 or string.len(pass) > 24 then
		log.error_print("password must be from 6 to 24 chars")
		return false
	end
	local _,_,x = string.find(pass,"[^0-9A-Za-z%.%_%-������]")
	if x ~= nil then
		log.error_print("password contains invalid character "..x.."\n")
		return false
	end
	return true
end

function toGMT(d)
	log.say("FIXME: GMT time conversion")
	return os.date("%c",d)
end

function mk_cookie(name,val,expires,path,domain,secure)
	local s = name .. "=" .. val
	if expires then
		s = s .. ";expires=" .. toGMT(expires)
	end
	if path then
		s = s .. ";path=" .. path
	end
	if domain then
		s = s .. ";domain=" .. domain
	end
	if secure then
		s = s .. ";secure"
	end
	return s
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
		("gmail.com")..
		(internal_state.password or "")
end

--------------------------------------------------------------------------------
-- Login to the gmail website
--
function gmail_login()
	if internal_state.login_done then
		return POPSERVER_ERR_OK
	end

	-- build the uri
	local password = internal_state.password
	local user = internal_state.name
	local uri = gmail_string.login
	local post = string.format(gmail_string.login_post,user,password)
	
	-- the browser must be preserved
	internal_state.b = browser.new()

	local b = internal_state.b

--	b.curl:setopt(curl.OPT_VERBOSE,1)
	b.curl:setopt(curl.OPT_SSL_VERIFYHOST,  2)
	b.curl:setopt(curl.OPT_USERAGENT,"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)")
	b.curl:setopt(curl.OPT_SSL_VERIFYPEER, 0)

	local extract_f = support.do_extract(
				internal_state,"cookie_val",gmail_string.cookieVal)
	local check_f = support.check_fail
	local retrive_f = support.retry_n(
				3,support.do_post(internal_state.b,uri,post))

	if not support.do_until(retrive_f,check_f,extract_f) then
		log.error_print("Login failed\n")
		return POPSERVER_ERR_AUTH
	end
	
	table.foreach(b:get_cookie("SID"),function(a,b)
			if a == "value" then
				internal_state.cookie_sid = b
			end
		end)

	internal_state.b = browser.new()

	local AuthCookie1 = mk_cookie("SID",internal_state.cookie_sid,nil,"/",".google.com",nil)
	local AuthCookie2 = mk_cookie("GV",internal_state.cookie_val,nil,"/",".google.com",nil)

-- TODO: Qui, se non creo un nuovo oggetto browser, non funziona,
-- commenta le prossime 5 riga e prova

	local b = internal_state.b

--	b.curl:setopt(curl.OPT_VERBOSE,1)
	b.curl:setopt(curl.OPT_SSL_VERIFYHOST,  2)
	b.curl:setopt(curl.OPT_USERAGENT,"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)")
	b.curl:setopt(curl.OPT_SSL_VERIFYPEER, 0)

	b:add_cookie(gmail_string.homepage,AuthCookie1)
	b:add_cookie(gmail_string.homepage,AuthCookie2)

	uri = gmail_string.login_checkcookie

	local body,err = b:get_uri(uri)

	local allOk = nil
	allOk = string.find(body,"Redirecting",1)

	-- check if do_extract has correctly extracted the session ID
	if allOk == nil then
		log.error_print("Login failed, unable to get cookie ID\n")
		return POPSERVER_ERR_AUTH
	end
	-- save all the computed data
	internal_state.login_done = true
	
	-- log the creation of a session
	log.say("Session started for " .. internal_state.name .. "@gmail.com " .. 
		"(" .. internal_state.cookie_val .. ")\n")
	return POPSERVER_ERR_OK
end

--------------------------------------------------------------------------------
-- The callbach factory for retr
--
function retr_cb(data)
	local a = stringhack.new()
	local FirstBlock = true
	
	return function(s,len)
		s = string.gsub(s,"\n","\r\n")
		s = a:dothack(s).."\0"
-- without the above string end of stream is: 00 00 00 0a 0a 2e 0d 0a
		-- \r = 13 = 0d                        \n \n .  \r \n
		-- \n = 10 = 0a

		-- fix that some clients don't know that the message was finished
		-- because at the end of the message we got \r\n\n
--		s = string.gsub(s,"\r$","")
		if FirstBlock then
			s = string.gsub(s,"^%s*","")
			s = string.gsub(s,"\r\r\n","\r\n")
			FirstBlock = false
		end

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
			
		s = global.a:tophack(s,global.lines_requested)
		s = string.gsub(s,"\n","\r\n")
		s = global.a:dothack(s).."\0"
			
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
--  gmail functions
-- ************************************************************************** --

-- Must save the mailbox name
function user(pstate,username)
	local name = freepops.get_name(username)

	local st,_,name,cmds = string.find(name, "([^#]*)[#]?(.*)")

	-- If user puts username as account#[box_name]@gmail.com
	-- FreePOPs will download messages from that box, default is inbox
	-- tested with "inbox" (normal inbox) and "all" (archive emails)
	internal_state.name = name
	if cmds == nil or cmds == "" then
		cmds = "inbox"
	end
	internal_state.cmds = cmds

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Must login
function pass(pstate,password)
	-- save the password
	internal_state.password = password

	-- check if the domain is valid
	if not check_sanity(internal_state.name,
			internal_state.password) then
		return POPSERVER_ERR_AUTH
	end

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
			return gmail_login()
		end
		
		-- exec the code loaded from the session tring
		c()

		log.say("Session loaded for " .. internal_state.name .. "@gmail.com " .. 
			"(" .. internal_state.cookie_val .. ")\n")
		
		return POPSERVER_ERR_OK
	else
		-- call the login procedure 
		return gmail_login()
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

	local b = internal_state.b

	local GMail_at_cookie = internal_state.gmail_at
	--mk_cookie("GMAIL_AT",internal_state.gmail_at,nil,"/",".google.com",nil)
	

--	b:add_cookie(gmail_string.homepage,GMail_at_cookie)

	local uri = gmail_string.delete
	-- act = [rd|ur|rc_^i]
	--        rd = mark as read
	--        ur = mark as unread
	--     rc_^i = move to archive
	--
	local post = string.format(gmail_string.delete_post, "rc_^i", GMail_at_cookie)

	-- here we need the stat, we build the uri and we check if we 
	-- need to delete something
	local delete_something = false;
	
	for i=1,get_popstate_nummesg(pstate) do
		if get_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE) then
			post = post .. string.format(gmail_string.delete_next,
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

	log.say("Session saved for " .. internal_state.name .. "@gmail.com" ..
			"(" .. internal_state.cookie_val .. ")\n")

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Fill the number of messages and their size
function stat(pstate)

	-- check if already called
	if internal_state.stat_done then
		return POPSERVER_ERR_OK
	end

	-- shorten names, not really important
	local b = internal_state.b
	local box = internal_state.cmds

	-- this string will contain the uri to get. it may be updated by 
	-- the check_f function, see later
	local uri = string.format(gmail_string.first, box, math.random(0, 1000000000))

	-- The action for do_until
	--
	-- uses mlex to extract all the messages uidl and size
	local function action_f (s)
		-- variables to hold temp parsing data
		-- variables en, en2 hold the last position of the previous search, to start next loop where we ended the first one
		local en, sUIDL, iNew, iStarred, sFrom
		local en2, parentUIDL, sSender
		local myemail = internal_state.name .. "@gmail.com"

		local sub_threads
		local body,err

		local MessageList = {}
		local email_stat = gmail_string.email_stat

		_, en, sUIDL, iNew, iStarred, sFrom = string.find(s, email_stat)
		while sUIDL ~= nil do
			_,_,sub_threads = string.find(sFrom, "%((%d+)%)$")
			table.insert(MessageList,{["sUIDL"]=sUIDL, ["iSize"]=1, ["iNew"]=iNew, ["iStarred"]=iStarred})
			if sub_threads ~= nil then
				-- get sub messages for this conversation
				parentUIDL = sUIDL
				uri = string.format(gmail_string.view_email_thread, parentUIDL, math.random(0, 1000000000))
				body,err = b:get_uri(uri)
				en2=0
				_, en2, sUIDL, iStarred, sSender = string.find(body, gmail_string.email_stat_sub)
				while sUIDL ~= nil do
					if sUIDL ~= parentUIDL and sSender ~= myemail then
						table.insert(MessageList,{["sUIDL"]=sUIDL, ["iSize"]=1, ["iNew"]=0, ["iStarred"]=iStarred})
					end
					_, en2, sUIDL, iStarred, sSender = string.find(body, gmail_string.email_stat_sub, en2)
				end
			end
			_, en, sUIDL, iNew, iStarred, sFrom = string.find(s, email_stat, en)
		end
		local n = table.getn(MessageList)

		if n == 0 then
			return true,nil
		end

		-- this is not really needed since the structure 
		-- grows automatically... maybe... don't remember now
		local nmesg_old = get_popstate_nummesg(pstate)
		local nmesg = nmesg_old + n
		set_popstate_nummesg(pstate,nmesg)

		local val = nil
		-- gets all the results and puts them in the popstate structure
		for i = 1,n do
			val = MessageList[n+1-i] -- n+1-i to get messages in reverse order oldest to newest
			sUIDL = val["sUIDL"]
			if not sUIDL then
				return nil,"Unable to parse page"
			end
			-- set it
			set_mailmessage_size(pstate,i+nmesg_old,1)
			set_mailmessage_uidl(pstate,i+nmesg_old,sUIDL)
		end
		
		return true,nil
	end

	-- check must control if we are not in the last page and 
	-- eventually change uri to tell retrive_f the next page to retrive
	local function check_f (s)  
		-- Currently only first page is parsed... later will implement multipage parsing
		local _,_, iStart, iShow, iTotal = string.find(s,gmail_string.next_checkC)
		if tonumber(iStart)+tonumber(iShow) < tonumber(iTotal) then
		-- TODO: furthur tests with more than 2 pages of emails
			-- change retrive behaviour
			uri = string.format(gmail_string.next, box, iStart+iShow, math.random(0, 1000000000))
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

	table.foreach(b:get_cookie("GMAIL_AT"),function(a,b)
			if a == "value" then
				internal_state.gmail_at = b
			end
		end)

	-- save the computed values
	internal_state["stat_done"] = true
	
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Fill msg uidl field
function uidl(pstate,msg)
	return common.uidl(pstate,msg)
end
-- -------------------------------------------------------------------------- --
-- Fill all messages uidl field
function uidl_all(pstate)
	return common.uidl_all(pstate)
end
-- -------------------------------------------------------------------------- --
-- Fill msg size
function list(pstate,msg)
	return common.list(pstate,msg)
end
-- -------------------------------------------------------------------------- --
-- Fill all messages size
function list_all(pstate)
	return common.list_all(pstate)
end
-- -------------------------------------------------------------------------- --
-- Unflag each message merked for deletion
function rset(pstate)
	return common.rset(pstate)
end
-- -------------------------------------------------------------------------- --
-- Mark msg for deletion
function dele(pstate,msg)
	return common.dele(pstate,msg)
end
-- -------------------------------------------------------------------------- --
-- Do nothing
function noop(pstate)
	return common.noop(pstate)
end

-- -------------------------------------------------------------------------- --
-- Get first lines message msg lines, must call 
-- popserver_callback to send the data
function retr(pstate,msg,data)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end

-- TODO: range checks doesn't work... need fixing... btw, in dele it works....
	if not common.check_range(pstate,msg) then
		log.say("Message index out of range.\n")
		-- log will say the above message, but no error message (-ERR) will be sent to the client.
		return POPSERVER_ERR_NOMSG
	end
	
	if common.check_range(pstate,msg) then
		-- the callback
		local cb = retr_cb(data)
		
		-- some local stuff
		local b = internal_state.b

		-- build the uri
		local uidl = get_mailmessage_uidl(pstate,msg)

		local uri = string.format(gmail_string.view_email,uidl,math.random(0, 1000000000))

		-- tell the browser to pipe the uri using cb
		local f,rc = b:pipe_uri(uri,cb)

		if not f then
			log.error_print("Asking for "..uri.."\n")
			log.error_print(rc.."\n")
			return POPSERVER_ERR_NETWORK
		end
-- TODO: after sending the message to the client, we need to set it as read
--       by b:post_uri(delete link and post data which contains act=rd&t=UIDL)
	end

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Get message msg, must call 
-- popserver_callback to send the data
--
--  TODO: Still TOP in not functioning, will cause complete message to be delivered to the client.
--
function top(pstate,msg,lines,data)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end

	-- some local stuff


	local b = internal_state.b

	-- build the uri
	local uidl = get_mailmessage_uidl(pstate,msg)
	local uri = string.format(gmail_string.view_email,uidl,math.random(0, 1000000000))

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
		return global.lines < 0 or global.bytes >= global.total_bytes
	end
	-- nothing to do
	local action_f = function(_)
		return true
	end

	-- go!
--	support.do_until(retrive_f,check_f,action_f)
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

	-- the serialization module
	if freepops.dofile("serialize.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end 

	-- the browser module
	if freepops.dofile("browser.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end

	freepops.need_ssl()

	-- the common implementation module
	if freepops.dofile("common.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end
	
	-- checks on globals
	freepops.set_sanity_checks()

	return POPSERVER_ERR_OK
end

-- EOF
-- ************************************************************************** --