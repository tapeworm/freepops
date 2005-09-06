-- ************************************************************************** --
--  FreePOPs @virgilio.it, @tin.it webmail interface
--  
--  $Id$
--  
--  Released under the GNU/GPL license
--  Written by Enrico Tassi <gareuselesinge@users.sourceforge.net>
-- ************************************************************************** --

-- these are used in the init function
PLUGIN_VERSION = "0.0.7"
PLUGIN_NAME = "Tin.IT"
PLUGIN_REQUIRE_VERSION = "0.0.14"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://www.freepops.org/download.php?file=tin.lua"
PLUGIN_HOMEPAGE = "http://www.freepops.org/"
PLUGIN_AUTHORS_NAMES = {"Enrico Tassi"}
PLUGIN_AUTHORS_CONTACTS = {"gareuselesinge (at) users (.) sourceforge (.) net"}
PLUGIN_DOMAINS = {"@tin.it","@virgilio.it"}
PLUGIN_PARAMETERS = {
	{name = "folder", description = {
		it = [[
Visto che potresti aver bisogno di scaricare altre cartelle oltre alle 
INBOX (che &egrave; quella di default) il plugin accetta il parametro folder 
e l' unico valore attualmente testato &egrave; Spam , ma anche altre cartelle
dovrebbero funzionare. Ecco un esempio di user name per controllare la 
cartella Spam: foo@virgilio.it?folder=Spam]],
		}	
	},
}
PLUGIN_DESCRIPTIONS = {
	it="Questo plugin vi per mette di leggere le mail che avete "..
	   "in una mailbox @virgilio.it , @tin.it . Per usare questo "..
	   "plugin dovete usare il vostro indirizzo email completo "..
	   "come user name e la vostra password reale come password.",
	en="This plugin is for italian users only."
}

-- ************************************************************************** --
--  strings
-- ************************************************************************** --

-- this are the webmail-dependent strings
--
-- Some of them are incomplete, in the sense that are used as string.format()
-- (read sprintf) arguments, so their %s and %d are filled properly
-- 
-- C, E, G are postfix respectively to Captures (lua string pcre-style 
-- expressions), mlex expressions, mlex get expressions.
-- 
local tin_string = {
	login = "http://aaacsc.virgilio.it/piattaformaAAA/controller/"..
		"AuthenticationServlet",
	login_post= "a3l=%s&a3p=%s&a3st=VCOMM&"..
		"a3aid=communicator&a3flag=0&"..
		"a3ep=http://communicator.virgilio.it/asp/login.asp&"..
		"a3afep=http://communicator.virgilio.it/asp/login.asp&"..
		"a3se=http://communicator.virgilio.it/asp/login.asp&"..
		"a3dcep=http://communicator.virgilio.it/asp/homepage.asp?s=005",
	-- domain, email, tincctoken
	login2 = "http://webmail.communicator.virgilio.it/"..
		"cp/ps/Main/login/PreLogin?"..
		"d=%s&sa=webmail&style=&mail=%s&token=%s",
	login2C = 'src="(/cp/ps/Mail/EmailList[^"]*)"',
	login2Ct="&t=([^&]+)",
	login2Cs="&s=([%d]+)",
	-- mesage list mlex
	statE = ".*<tr>.*<td>.*<input>.*</td>.*<td>.*<a>.*<img>.*</a>.*</td>.*<td>.*<a>.*<img>.*</a>.*</td>.*<td>.*<a>.*<img>.*</a>.*</td>.*<td>.*<a.*Email>.*</a>.*</td>.*<td>.*</td>.*<td>.*<a>.*</a>.*</td>.*<td>.*</td>.*</tr>",
	statG = "O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<X>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>X<O>O<O>",
	
	-- The uri for the first page with the list of messages
	-- parameters all %s except fi that is %d: 
	--   wherearewe(), folder, domain, username, t, s, fi
	first = "http://%s/cp/ps/Mail/EmailList?"..
		"fp=%s&d=%s&an=&u=%s&t=%s&style="..
		"&l=it&s=%s&fi=%d&sc=&sd=",
	-- The regex that, if not found, means we are on the last stat page
	no_next = "href%s*=%s*'/cp/ps/Mail/EmailList[^']*fi=[^']*'>&gt;&gt;",
	list_href = "href%s*=%s*'/cp/ps/Mail/EmailList",
	-- The capture to understand if the session ended
	timeoutC = '(window.parent.location.*/mail/main?.*err=24)',
	-- The uri to save a message (read download the message)
	--   whearewe, mailbox, username, username, uidl, t, s
	save = "http://%s/cp/ps/Mail/Email"..
		"?sh=&fp=%s&d=virgilio.it&sd=&sc=&an=%s&u=%s&"..
		"uid=%s&t=%s&style=&l=it&s=%s",	
	body_start = [[
</script>	
			<br>
			<br>
          </div>]],
	body_end = [[</div></td>%s*<td width="5"><spacer type="block" width="5" height="1"></td>%s*<td width="1" bgcolor="#FFFFFF"><spacer type="block" width="1" height="1"></td>%s*</tr>%s*</table>%s*<!%-%-FINE TABELLA LISTING MAIL%-%->]],
	 attachE = ".*<a.*href='/cp/ps/Mail/ViewAttachment>.*<img>.*</a>",
	 attachG = "O<X>O<O>X<O>",
	-- The uri to delete some messages
	--   whearewe(), domain, username, t, s, 
	delete = "http://%s/cp/ps/Mail/Delete?d=%s&u=%s&t=%s&style=&l=it&s=%s",
	-- folder, uidl, username
	delete_post = "fp=%s&uid=%s&dellist=&an=%s",
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
	session_id_s = nil,
	session_id_t = nil,
	domain = nil,
	name = nil,
	password = nil,
	b = nil,
	folder="INBOX"
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
		(internal_state.password or "")..
		(internal_state.folder or "")
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
	
	-- the browser must be preserved
	internal_state.b = browser.new()

	local b = internal_state.b
 	--b:verbose_mode()

	-- step 1: fetch bisquits
	local post = string.format(tin_string.login_post,pop_login,password)
	local body, err = b:post_uri(tin_string.login,post)
	if body == nil then
		log.error_print("Error getting "..tin_string.login..": "..err)
		return POPSERVER_ERR_AUTH
	end

	-- step 2: get session id_s and id_t
	local tincctoken = assert(b:get_cookie("tincctoken"),
		"unable to find cookie tincctoken").value
	local url = string.format(tin_string.login2, domain,
		curl.escape(pop_login), curl.unescape(tincctoken))
	local body,err = b:get_uri(url)
	if body == nil then
		log.error_print("Error getting "..url..": "..err)
		return POPSERVER_ERR_AUTH
	end
	local _,_, capt = string.find(body, tin_string.login2C)
	local _,_,t = string.find(capt, tin_string.login2Ct) 
	local _,_,s = string.find(capt, tin_string.login2Cs) 
	
	internal_state.session_id_s = s
	internal_state.session_id_t = t
	
	if internal_state.session_id_s == nil or
	   internal_state.session_id_t == nil then
		log.error_print("Login failed\n")
		return POPSERVER_ERR_AUTH
	end

	-- save all the computed data
	internal_state.login_done = true
	
	-- log the creation of a session
	log.say("Session started for " .. internal_state.name .. "@" .. 
		internal_state.domain .. 
		"(" .. internal_state.session_id_t .. ", " .. 
			internal_state.session_id_s .. ")\n")

	return POPSERVER_ERR_OK
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
	internal_state.folder = freepops.MODULE_ARGS.folder or "INBOX"
	
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
			"(" .. internal_state.session_id_s .. ", " ..
			internal_state.session_id_t .. ")\n")
		
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
	local session_id_s = internal_state.session_id_s
	local session_id_t = internal_state.session_id_t
	local domain = internal_state.domain
	local user = internal_state.name
	local pop_login = user .. "@" .. domain
	local folder = internal_state.folder
	
	local uri = string.format(tin_string.delete, popserver, domain, 
		user, session_id_t, session_id_s)
	
	for i=1,get_popstate_nummesg(pstate) do
		if get_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE) then
			local uidl = get_mailmessage_uidl(pstate,i)
			local post = string.format(tin_string.delete_post,
				folder, uidl, user)
			local body, err = b:post_uri(uri, post)
			print(uri, post)--, body)
			if body == nil then
				log.error_print("Error getting "..uri..":"..err)
				return POPSERVER_ERR_UNKNOWN
			end
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
		internal_state.session_id_t .. ", " .. 
		internal_state.session_id_s .. ")\n")

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
	local session_id_s = internal_state.session_id_s
	local session_id_t = internal_state.session_id_t
	local b = internal_state.b
	local popserver = b:wherearewe()
	local domain = internal_state.domain
	local user = internal_state.name
	local pop_login = user .. "@" .. domain

	-- this string will contain the uri to get. it may be updated by 
	-- the check_f function, see later
	local page = 1
	local uri = string.format(tin_string.first,
		b:wherearewe(), internal_state.folder,
		domain, user, session_id_t, session_id_s, page)
	
	-- The action for do_until
	--
	-- uses mlex to extract all the messages uidl and size
	local function action_f (s) 
		-- calls match on the page s, with the mlexpressions
		-- statE and statG
		local x = mlex.match(s,tin_string.statE,tin_string.statG)
	
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
			local uidl = x:get (0,i-1) 
			local size = x:get (1,i-1)

			-- arrange message size
			local k,m = nil,nil
			_,_,k = string.find(size,"([Kk][Bb])")
			_,_,m = string.find(size,"([Mm][Bb])")
			_,_,size = string.find(size,"([%.%d]+)")
			_,_,uidl = string.find(uidl,'uid=([%d]+)')

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
	local count = 0
	local function next_page()
		page = page + 10
		uri = string.format(tin_string.first,
			b:wherearewe(), internal_state.folder,
			domain, user, session_id_t, session_id_s, page)
		return false
	end
	local function check_f (s) 
		local tmp = string.find(s,tin_string.no_next)
		if tmp ~= nil then
			return next_page()
		else
			-- we are on the last page only if we have seen
			-- this 3 times
			count = count + 1
			local how_many_refs = 0
			for x in string.gfind(s, tin_string.list_href) do
				how_many_refs = how_many_refs + 1
			end
			-- there should be links before and after the list
			if math.mod(how_many_refs, 2) ~= 0 then
				log.error_print("Error in counting list_href")
				return true
			end
			how_many_refs = how_many_refs / 2
			if count > how_many_refs then 
				return true 
			else
				return next_page()
			end
		end
	end

	-- this is simple and uri-dependent
	local function retrive_f ()  
		-- print("getting "..uri)
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
			
			session_id_s = internal_state.session_id_s
			session_id_t = internal_state.session_id_t
			b = internal_state.b
			-- popserver has not changed
			page = 1
			uri = string.format(tin_string.first,
				internal_state.folder,
				domain, user, session_id_t, session_id_s, page)
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
-- 
function tin_parse_webmessage(wherearewe, data)
	local head, body, body_html, attach = nil, nil, nil, {}

	-- extract headers 
	local headersE = ".*<script>.*var *hd *=</script>.*<br>.*<br>.*</div>"
	local headersG = "O<O>X<O>O<O>O<O>O<O>"
	local x = mlex.match(data, headersE, headersG)
	local headers = x:get(0,0)
	local _, _, head = string.find(headers, 'var%s*hd%s*=%s*"([^"]+)"%s*;')
	head = string.gsub(head, "\\n\\n", "")
	head = string.gsub(head, "\\r", "\r")
	head = string.gsub(head, "\\n", "\n")
	head = string.gsub(head, "        ", "\t")
	head = string.gsub(head, "\\&quot;", "\"")
	head = string.gsub(head, "&lt;", "<")
	head = string.gsub(head, "&gt;", ">")
	head = mimer.remove_lines_in_proper_mail_header(head, {"content%-type"})
	
	-- extract body
	local _, begin_body = string.find(data, tin_string.body_start)
	local end_body, _ = string.find(data, tin_string.body_end)
	body_html = string.sub(data, begin_body + 1, end_body - 1)
	
	-- extract attachments
	local x = mlex.match(data, tin_string.attachE, tin_string.attachG) 
	for i = 1, x:count() do
		local url = x:get(0,i-1)
		local name = x:get(1,i-1)

		local _, _, name = string.find(name, "^(.*) %(")

		local _, _, url = string.find(url, 
			"href%s*=%s*'(/cp/ps/Mail/ViewAttachment[^']*)'")
		
		attach[name] = "http://"..wherearewe..url
		table.setn(attach,table.getn(attach) + 1)
	end
	
	return head, body, body_html, attach
end

function retr(pstate,msg,data)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end
	
	-- some local stuff
	local session_id_t = internal_state.session_id_t
	local session_id_s = internal_state.session_id_s
	local b = internal_state.b
	local popserver = b:wherearewe()
	local domain = internal_state.domain
	local user = internal_state.name
	local pop_login = user .. "@" .. domain
	local folder = internal_state.folder
	
	-- build the uri
	local uidl = get_mailmessage_uidl(pstate,msg)
	--   whearewe, mailbox, username, username, uidl, t, s
	local uri = string.format(tin_string.save,b:wherearewe(),
		folder, user, user, uidl, session_id_t, session_id_s)
	
	-- tell the browser to pipe the uri using cb
	local f,rc = b:get_uri(uri)

	if f == nil then
		log.error_print("Asking for "..uri.."\n")
		log.error_print(rc.."\n")
		return POPSERVER_ERR_NETWORK
	end

	local wherearewe = b:wherearewe()
	local head,body,body_html,attach = tin_parse_webmessage(wherearewe, f)
	local cb = mimer.callback_mangler(common.retr_cb(data))
	mimer.pipe_msg(head,body,body_html,"http://"..wherearewe,attach,b,cb)
		
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
	local session_id_t = internal_state.session_id_t
	local session_id_s = internal_state.session_id_s
	local b = internal_state.b
	local popserver = b:wherearewe()
	local domain = internal_state.domain
	local user = internal_state.name
	local pop_login = user .. "@" .. domain
	local folder = internal_state.folder
	
	-- build the uri
	local uidl = get_mailmessage_uidl(pstate,msg)
	--   whearewe, mailbox, username, username, uidl, t, s
	local uri = string.format(tin_string.save,b:wherearewe(),
		folder, user, user, uidl, session_id_t, session_id_s)
	
	-- tell the browser to pipe the uri using cb
	local f,rc = b:get_uri(uri)

	if f == nil then
		log.error_print("Asking for "..uri.."\n")
		log.error_print(rc.."\n")
		return POPSERVER_ERR_NETWORK
	end

	local wherearewe = b:wherearewe()
	local head,body,body_html,attach = tin_parse_webmessage(wherearewe, f)
	local global = common.new_global_for_top(lines,nil)
	local cb = mimer.callback_mangler(common.top_cb(global,pdata,true))
	mimer.pipe_msg(head,body,body_html,"http://"..wherearewe,attach,b,cb)
		
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

	-- the common implementation module
	if freepops.dofile("common.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end
	
	-- the mimer module
	if freepops.dofile("mimer.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end
	
	-- checks on globals
	freepops.set_sanity_checks()

	return POPSERVER_ERR_OK
end

-- EOF
-- ************************************************************************** --
