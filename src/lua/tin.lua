-- ************************************************************************** --
--  FreePOPs @virgilio.it, @tin.it webmail interface
--  
--  $Id$
--  
--  Released under the GNU/GPL license
--  Written by Enrico Tassi <gareuselesinge@users.sourceforge.net>
-- ************************************************************************** --

-- these are used in the init function
PLUGIN_VERSION = "0.0.1"
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
-- <tr><td width=6 bgcolor=#FCF3E2><spacer type="block" height=1 width=6></td>
--             <td colspan=2 align=center width="41" ><a href="/mail/MessageRead?sid=6966E8704F792498961C294F5FDFE6D2C9844735&userid=gareuselesinge2%40virgilio.it&seq=+Q&auth=+A&srcfolder=INBOX&uid=1&srch=0&style=comm4_IT"><img
--                border=0 height=15 width=5  src=http://graphic.cp.virgilio.it/graphics/comm3_IT/priority_normal.gif ><img
--                border=0 height=15 width=15 src=http://graphic.cp.virgilio.it/graphics/comm3_IT/new.gif ><script>
--               doWriteImageLink("","0","attach_none.gif");
--			   </script></a></td>
--            <td align=center width="20"><input type=checkbox name=msguid value="1"></td>
--            <td width="175"><p class=spazio3 ><b>
--                <a href="/mail/MessageRead?sid=6966E8704F792498961C294F5FDFE6D2C9844735&userid=gareuselesinge2%40virgilio.it&seq=+Q&auth=+A&srcfolder=INBOX&uid=1&srch=0&style=comm4_IT" class="linkrossoscuro10">tinitfree@tin.it</a>
--                </b></p></td>
--
--            <td width="76" class=testomarronescuro10 align=center><p class=spazio3 ><b>Mag 18</b></p></td>
--            <td width="225"  class=testomarronescuro10><p class=spazio3 ><b><a href="/mail/MessageRead?sid=6966E8704F792498961C294F5FDFE6D2C9844735&userid=gareuselesinge2%40virgilio.it&seq=+Q&auth=+A&srcfolder=INBOX&uid=1&srch=0&style=comm4_IT" class="linkrossoscuro10">Benvenuto in tin.it Free</A></b></p></td>
--            <td  width="71" colspan=2 class=testomarronescuro10><p class=spazio3 ><b>2.9 KB</b></p></td>
--          </tr>
	statE = ".*<tr>.*<td>.*<input.*value.*=.*[[:digit:]]+.*>.*</td>"..
		".*<td>.*<img>.*</td>.*<td>.*<img>.*</td>.*<td>.*<img>"..
		".*</td>.*<td>.*<img>.*</td>.*<td>.*<img>.*</td>.*<td>"..
		".*<a>.*<img>.*</a>.*<a>[.*]{b}.*{/b}[.*]</a>.*</td>.*<td>"..
		".*<img>.*</td>.*<td>.*<a>[.*]{b}.*{/b}[.*]</a>.*</td>.*<td>"..
		".*<img>.*</td>.*<td>.*</td>.*<td>.*<img>.*</td>"..
		".*<td>[.*]{b}.*{/b}[.*]</td>.*</tr>",
	-- This is the mlex get expression to choose the important fields 
	-- of the message list page. Used in combination with statE
	statG = "O<O>O<O>O<X>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>"..
		"O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>[O]{O}O{O}[O]<O>"..
		"O<O>O<O>O<O>O<O>O<O>O<O>[O]{O}O{O}[O]<O>O<O>O<O>O<O>O<O>"..
		"O<O>O<O>O<O>O<O>O<O>O<O>[O]{O}X{O}[O]<O>O<O>",
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
-- checks domain validity
--
function check_domain(s)
	return tin_domains[s]
end

--------------------------------------------------------------------------------
-- we don't want to break the webmail
--
function check_sanity(name,domain,pass)
	print("FIXME: do as the js")
	return true
end

function toGMT(d)
	print("FIXME: GMT time conversion")
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
	-- FIX may be faster :)
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
-- Login to the libero website
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
	local bisquit1 = mk_cookie("CPIULOGIN","",nil,"/",".virgilio.it",nil)
	local txcpiu = aaa_encode(pop_login,password,curl.escape(
		tin_string.tinsso_dxurl))
	local txmail = aaa_encode(pop_login,password,tin_string.tinsso_wmail)
	local bisquit2 = mk_cookie("CPTX",txcpiu,nil,"/",".virgilio.it",nil)
	local bisquit3 = mk_cookie("CPWM",txmail,nil,"/",".virgilio.it",nil)
	
	-- the browser must be preserved
	internal_state.b = browser.new()

	local b = internal_state.b

	b.curl:setopt(curl.OPT_VERBOSE,1)

--	local head = b:get_head("http://communicator.virgilio.it")
--	b:show()
--	print(head)
	b:add_cookie("http://communicator.virgilio.it",bisquit3)
	b:add_cookie("http://communicator.virgilio.it",bisquit2)
	b:add_cookie("http://communicator.virgilio.it",bisquit1)
--	b:show()
	local body,err = b:post_uri(uri,post)
--	print("Richiedo la uri: "..uri)
--	b:show()
--	print(body)
--
	local body,err = b:get_uri("http://communicator.virgilio.it/mail/webmail.asp")
local f = io.open("out.html","w")
	f:write(body)
	f:close()

	local _,_,sid = string.find(body,'LoadFrames%(".*sid=(%w*)%&')

	print("SID="..sid)

	b:show()
	
	b.referrer = "http://phx3e.cp.virgilio.it/mail/Navigation?sid="..sid.."&userid=gareuselesinge2%40virgilio.it&seq=+Q&auth=+A&style=comm4_IT"
	
	local body,err = b:get_uri("http://"..b:wherearewe().."/mail/MessageList?sid="..sid.."1&userid="..curl.escape(pop_login).."&seq=+Q&auth=+A&srcfolder=INBOX&chk=1&style=comm4_IT")
	
	--body = b:get_uri("http://communicator.virgilio.it/mail/webmail.asp")
	--print(body)

f = io.open("out2.html","w")
	f:write(body)
	f:close()

	return POPSERVER_ERR_AUTH
	
--	-- the functions for do_until
--	-- extract_f uses the support function to extract a capture specifyed 
--	--   in libero_string.sessionC, and pu ts the result in 
--	--   internal_state["session_id"]
--	-- check_f the is the failure funtion, that means that the do_until
--	--   will not repeat
--	-- retrive_f is the function that do_retrive the uri uri with the
--	--   browser b. The function will be retry_n 3 times if it fails
--	local extract_f = support.do_extract(
--		internal_state,"session_id",libero_string.sessionC)
--	local check_f = support.check_fail
--	local retrive_f = support.retry_n(
--		3,support.do_retrive(internal_state.b,uri))
--
--	-- maybe implement a do_once
--	if not support.do_until(retrive_f,check_f,extract_f) then
--		-- not sure that it is a password error, maybe a network error
--		-- the do_until will log more about the error before us...
--		-- maybe we coud add a sanity_check function to do until to
--		-- check if the received page is a server error page or a 
--		-- good page.
--		log.error_print("Login failed\n")
--		return POPSERVER_ERR_AUTH
--	end
--
--	-- check if do_extract has correctly extracted the session ID
--	if internal_state.session_id == nil then
--		log.error_print("Login failed, unable to get session ID\n")
--		return POPSERVER_ERR_AUTH
--	end
--		
--	-- save all the computed data
--	internal_state.popserver = "wpop" .. popnumber .. site
--	internal_state.login_done = true
--	
--	-- log the creation of a session
--	log.say("Session started for " .. internal_state.name .. "@" .. 
--		internal_state.domain .. 
--		"(" .. internal_state.session_id .. ")\n")
--
--	return POPSERVER_ERR_OK
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
				return nil,{
					error="Session ended,unable to recover"
					}
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
		log.error_print(rc.error.."\n")
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
		base = 2--2048,
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
