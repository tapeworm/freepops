-- ************************************************************************** --
--  FreePOPs @virgilio.it, @tin.it webmail interface
--  
--  $Id$
--  
--  Released under the GNU/GPL license
--  Written by Enrico Tassi <gareuselesinge@users.sourceforge.net>
-- ************************************************************************** --

-- these are used in the init function
PLUGIN_VERSION = "0.0.3"
PLUGIN_NAME = "Tin.IT"

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
local tin_string = {
	tinsso_dxurl="",
	tinsso_wmail="webmail_IT",
	-- The uri the browser uses when you click the "login" button
	login = "http://aaacsc.virgilio.it/piattaformaAAA/controller/"..
		"AuthenticationServlet",
	login_post= "a3l=%s&a3p=%s&a3st=VCOMM&"..
		"a3aid=communicator&a3flag=0&"..
		"a3ep=http://communicator.virgilio.it/asp/login.asp&"..
		"a3afep=http://communicator.virgilio.it/asp/login.asp&"..
		"a3se=http://communicator.virgilio.it/asp/login.asp&"..
		"a3dcep=http://communicator.virgilio.it/asp/homepage.asp?s=005",
	homepage="http://communicator.virgilio.it",
	webmail="http://communicator.virgilio.it/mail/webmail.asp",
	-- This is the capture to get the session ID from the login-done webpage
	sessionC = 'LoadFrames%(".*sid=(%w*)%&',
	-- mesage list mlex
	statE = ".*<tr>.*<td>.*<spacer>.*</td>.*<td>.*<a>.*<img>.*<img>.*<script>.*</script>.*</a>.*</td>.*<td>.*<input>.*</td>.*<td>.*<p>[.*]{b}.*<a>.*</a>.*{/b}[.*]</p>.*</td>.*<td>.*<p>[.*]{b}.*{/b}[.*]</p>.*</td>.*<td>.*<p>[.*]{b}.*<a>.*</A>.*{/b}[.*]</p>.*</td>.*<td>.*<p>[.*]{b}.*[KkMm]?[Bb]?{/b}[.*]</p>.*</td>.*</tr>",
	statG = "O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<X>O<O>O<O>O<O>[O]{O}O<O>O<O>O{O}[O]<O>O<O>O<O>O<O>[O]{O}O{O}[O]<O>O<O>O<O>O<O>[O]{O}O<O>O<O>O{O}[O]<O>O<O>O<O>O<O>[O]{O}X{O}[O]<O>O<O>O<O>",
	-- The uri for the first page with the list of messages
	first = "http://%s/mail/MessageList?sid=%s&userid=%s&"..
		"seq=+Q&auth=+A&srcfolder=INBOX&chk=1&style=comm4_IT",
	-- The uri to get the next page of messages
	next = "http://%s/mail/MessageList?sid=%s&userid=%s&"..
		"seq=+Q&auth=+A&srcfolder=INBOX&chk=1&style=comm4_IT&"..
		"start=%d&end=%d",
	-- some stuff for the mail list browsing
	rangeC='\n%s*rng%s*=%s*"(%d+)%-(%d+)"%s*;',
	totalC='\n%s*var%s*totalpage%s*=%s*(%d+)%s*/%s*page%s*;',
	stepC="\n%s*var%s*page%s*=%s*(%d+)%s*;",
	-- The capture to understand if the session ended
	timeoutC = '(window.parent.location.*/mail/main?.*err=24)',
	-- The uri to save a message (read download the message)
	save = "http://%s/mail/MessageDownload?sid=%s&userid=%s&"..
		"seq=+Q&auth=+A&srcfolder=INBOX&uid=%s&srch=0&style=comm4_IT",	
	-- The uri to delete some messages
	delete = "http://%s/mail/MessageErase",
	-- The peace of uri you must append to delete to choose the messages 
	-- to delete
	delete_post = "sid=%s&userid=%s&"..
		"seq=+Q&auth=+A&srcfolder=INBOX&chk=1&style=comm4_IT&",
	delete_next = "msguid=%s&"
}

tin_domains = {
	["virgilio.it"] = true,
	["tin.it"] = true
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
-- checks domain validity
--
function check_domain(s)
	return tin_domains[s]
end

--------------------------------------------------------------------------------
-- we don't want to break the webmail
--
function check_sanity(name,domain,pass)
	-- FIXME no domain check for subdomains of tin.it
	if string.len(name) < 3 or string.len(name) > 30 then
		log.error_print("username must be from 3 to 30 chars")
		return false
	end
	local _,_,x = string.find(name,"([^0-9a-z%.%_%-])")
	if x ~= nil then
		log.error_print("username contains invalid character "..x.."\n")
		return false
	end	
	if string.len(pass) < 4 or string.len(pass) > 24 then
		log.error_print("password must be from 4 to 24 chars")
		return false
	end
	local _,_,x = string.find(pass,"[^0-9A-Za-z%.%_%-אטילעש]")
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
	local s = name .. "=" .. curl.escape(val)
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

function asc2hex(d)
	local t = {}
	-- FIXME may be faster :)
	for i=1,string.len(d) do
		table.insert(t,string.format("%X",string.byte(d,i)))
	end
	return table.concat(t)
end

function aaa_encode(u,p,s)
	return asc2hex(curl.escape(base64.encode(u.."|"..p.."|"..s.."|")))
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
-- Login to the tin website
--
function tin_login()
	if internal_state.login_done then
		return POPSERVER_ERR_OK
	end

	-- build the uri
	local password = internal_state.password
	local domain = internal_state.domain
	local user = internal_state.name
	local pop_login = user .. "@" .. domain
	local uri = tin_string.login
	local post = string.format(tin_string.login_post,pop_login,password)
	local txcpiu = aaa_encode(pop_login,password,curl.escape(
		tin_string.tinsso_dxurl))
	local txmail = aaa_encode(pop_login,password,tin_string.tinsso_wmail)
	
	-- we are really greedy :) gnam! gnam!
	local bisquit1 = mk_cookie("CPIULOGIN","",nil,"/",".virgilio.it",nil)
	local bisquit2 = mk_cookie("CPTX",txcpiu,nil,"/",".virgilio.it",nil)
	local bisquit3 = mk_cookie("CPWM",txmail,nil,"/",".virgilio.it",nil)
	local bisquit4 = mk_cookie("PHXID","",nil,"/",".virgilio.it",nil)
	local bisquit5 = mk_cookie("PHXPAGE","",nil,"/",".virgilio.it",nil)
	
	-- the browser must be preserved
	internal_state.b = browser.new()

	local b = internal_state.b

--	b.curl:setopt(curl.OPT_VERBOSE,1)

	b:add_cookie(tin_string.homepage,bisquit3)
	b:add_cookie(tin_string.homepage,bisquit2)
	b:add_cookie(tin_string.homepage,bisquit1)
	
	local body,err = b:post_uri(uri,post)

	b:add_cookie(tin_string.homepage,bisquit4)
	b:add_cookie(tin_string.homepage,bisquit5)
	
	local extract_f = support.do_extract(
		internal_state,"session_id",tin_string.sessionC)
	local check_f = support.check_fail
	local retrive_f = support.retry_n(
		3,support.do_retrive(internal_state.b,tin_string.webmail))

	if not support.do_until(retrive_f,check_f,extract_f) then
		log.error_print("Login failed\n")
		return POPSERVER_ERR_AUTH
	end

	-- check if do_extract has correctly extracted the session ID
	if internal_state.session_id == nil then
		log.error_print("Login failed, unable to get session ID\n")
		return POPSERVER_ERR_AUTH
	end
		
	-- save all the computed data
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
--  Tin functions
-- ************************************************************************** --

-- Must save the mailbox name
function user(pstate,username)
	
	-- extract and check domain
	local domain = freepops.get_domain(username)
	local name = freepops.get_name(username)

	-- check if the domain is valid
	if not check_domain(domain) then
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

	-- check if the domain is valid
	if not check_sanity(internal_state.name,
			internal_state.domain,
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
			return tin_login()
		end
		
		-- exec the code loaded from the session tring
		c()

		log.say("Session loaded for " .. internal_state.name .. "@" .. 
			internal_state.domain .. 
			"(" .. internal_state.session_id .. ")\n")
		
		return POPSERVER_ERR_OK
	else
		-- call the login procedure 
		return tin_login()
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
	local popserver = b:wherearewe()
	local session_id = internal_state.session_id
	local domain = internal_state.domain
	local user = internal_state.name
	local pop_login = user .. "@" .. domain
	
	local uri = string.format(tin_string.delete,popserver)
	local post = string.format(tin_string.delete_post,session_id,pop_login)

	-- here we need the stat, we build the uri and we check if we 
	-- need to delete something
	local delete_something = false;
	
	for i=1,get_popstate_nummesg(pstate) do
		if get_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE) then
			post = post .. string.format(tin_string.delete_next,
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
	local session_id = internal_state.session_id
	local b = internal_state.b
	local popserver = b:wherearewe()
	local domain = internal_state.domain
	local user = internal_state.name
	local pop_login = user .. "@" .. domain

	-- this string will contain the uri to get. it may be updated by 
	-- the check_f function, see later
	local uri = string.format(tin_string.first,popserver,
		session_id,curl.escape(pop_login))
	
	-- The action for do_until
	--
	-- uses mlex to extract all the messages uidl and size
	local function action_f (s) 
		-- calls match on the page s, with the mlexpressions
		-- statE and statG
		local x = mlex.match(s,tin_string.statE,tin_string.statG)
	
		x:print()
		
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
			_,_,m = string.find(size,"([Mm][Bb])")
			_,_,size = string.find(size,"([%.%d]+)")
			_,_,uidl = string.find(uidl,'value="([%d]+)"')

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
		-- FIXME use the <form> fields instead
		local _,_,_,to = string.find(s,
			tin_string.rangeC)
		local _,_,last = string.find(s,
			tin_string.totalC)
		if last == nil or to == nil then
			error("unable to capture last or to")
		end
		--print("$$\n"..s.."$$\n")
		--print("-->",to,last)
		if to < last then
			-- change retrive behaviour
			local _,_,step = string.find(s,
				tin_string.stepC)
			if step == nil then
				log.error_print("unable to capture step")
				return true
			end
			local start = last - to
			local end_ = math.max(0,start-step)
			uri = string.format(tin_string.next,popserver,
				session_id,curl.escape(pop_login),
				start,end_)
			-- continue the loop
			return false
		else
			return true
		end
	end

	-- this is simple and uri-dependent
	local function retrive_f ()  
		--print("getting "..uri)
		local f,err = b:get_uri(uri)
		if f == nil then
			return f,err
		end
		
		local _,_,c = string.find(f,tin_string.timeoutC)
		if c ~= nil then
			internal_state.login_done = nil
			session.remove(key())

			local rc = tin_login()
			if rc ~= POPSERVER_ERR_OK then
				return nil,"Session ended,unable to recover"
			end
			
			session_id = internal_state.session_id
			b = internal_state.b
			-- popserver has not changed
			
			uri = string.format(tin_string.first,popserver,
				session_id,curl.escape(pop_login))
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
uidl = common.uidl

-- -------------------------------------------------------------------------- --
-- Fill all messages uidl field
uidl_all = common.uidl_all

-- -------------------------------------------------------------------------- --
-- Fill msg size
list = common.list

-- -------------------------------------------------------------------------- --
-- Fill all messages size
list_all = common.list_all

-- -------------------------------------------------------------------------- --
-- Do nothing
noop = common.noop

-- -------------------------------------------------------------------------- --
-- Unflag each message merked for deletion
rset = common.rset

-- -------------------------------------------------------------------------- --
-- Mark msg for deletion
dele = common.dele

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
		
	return POPSERVER_ERR_OK
end

-- EOF
-- ************************************************************************** --
