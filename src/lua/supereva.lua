-- ************************************************************************** --
--  FreePOPs @foo.xx webmail interface, the plugin made in the tutorial,
--  see the manal for more infos about this simple example
-- 
--  $Id$
-- 
--  Released under the GNU/GPL license
--  Written by Me <Me@myhouse>
-- ************************************************************************** --


PLUGIN_VERSION = "0.2.5"
PLUGIN_NAME = "Supereva web mail"
PLUGIN_REQUIRE_VERSION = "0.2.0"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://www.freepops.org/download.php?module=supereva.lua"
PLUGIN_HOMEPAGE = "http://www.freepops.org"
PLUGIN_AUTHORS_NAMES = {"Andrea Dalle Molle","Enrico Tassi","Visioning","Viruzzo"}
PLUGIN_AUTHORS_CONTACTS = {"Tund3r (at) fastwebnet (dot) it",
       "gareuselesinge (at) users (dot) sourceforge (dot) net","unknown","unknown"}
PLUGIN_DOMAINS = {"@supereva.it","@supereva.com","@freemail.it","@freeweb.org","@mybox.it","@superdada.com","@cicciociccio.com","@mp4.it","@dadacasa.com","@clarence.com","@concento.it"}
PLUGIN_PARAMETERS = {
	{name="onlynew", description={
		en="Set this to 1 if you want to see only new messages. Should be useless since version 0.0.6",
		it="Mettilo a 1 se non vuoi che vengano scaricati 2 volte i messaggi se lasci una copia dei messaggi sul server. Verranno visualizzati solo i messaggi nuovi. Dalla versione 0.0.6 non dovrebbe essercene bisogno."}},
}
PLUGIN_DESCRIPTIONS = {
	it=[[Questo plugin consente di scaricare la posta del portale supereva.it]],
	en=[[This plugin is for the supereva.it portal]]
}

-- ------------------------------------------------------------------------ --
-- Global plugin state
supereva_globals= {
	username="nothing",
	password="nothing",
	browser=nil
}

-- ------------------------------------------------------------------------ --
-- Mapping: handling new/ --> cur/ uidls
stat_mapping = {

}

function get_stat_mapping(k)
	return stat_mapping[k] or k
end

-- ------------------------------------------------------------------------ --
--  Constants
local strings = {
	
	login_url = "http://it.email.dada.net/cgi-bin/sn_my/login.chm?"..
		"uri=http://it.email.dada.net/cgi-bin/login.chm&ser=email&username=%s&password=%s",
  
	first = "http://it.email.dada.net/cgi-bin/main.chm?"..
		"mailfolder=in&proaction=readmailbox&mlt_msgs=%d",
  
	base = 'http://it.email.dada.net/cgi-bin/',

	body_begin = '<div id="mailbody" class="mailtext">',

	body_end = '</div><!-- google_ad_section_end --></td>\n*',

	body_end_with_attach = '</div><!-- google_ad_section_end --></td>\n*</tr>\n\n*'..
		'<tr>\n*<td colspan="2">\n\n*<table class="attachment">',

	head_begin = '</table>\n<div style="background:#DFEEBD;">',
  
	head_end = '</div>\n\n*<div id="testomail">',

	get_url = "http://it.email.dada.net/cgi-bin/nrmail03.chm?"..
		"setflags=yes&msgnum=%s&mailaction=read&mailfolder=in",

	next_page = "mailfolder=in&changefolder=changefolder&proaction=readmailbox"..
		"&check_mail=&mlt_msgs=%d&orderby="
}

--------------------------------------------------------------------------------
-- Serialize the internal_state
--
-- serial. serialize is not enough powerful to correcly serialize the 
-- internal state. The field b is the problem. b is an object. This means
-- that it is a table (and no problem for this) that has some field that are
-- pointers to functions. this is the problem. there is no easy way for the 
-- serial module to know how to serialize this. so we call b:serialize 
-- method by hand hacking a bit on names
--
function serialize_state()
	supereva_globals.stat_done = false;
	
	return serial.serialize("supereva_globals",supereva_globals) ..
		supereva_globals.browser:serialize("supereva_globals.browser")
end

--------------------------------------------------------------------------------
-- The key used to store session info
--
-- This key must be unique for all webmails, since the session pool is one 
-- for all the webmails
--
function key()
	return (supereva_globals.username or "")..
		(supereva_globals.password or "")..
		(supereva_globals.folder or "")
end


-- ************************************************************************** --
--
-- This is the interface to the external world. These are the functions
-- that will be called by FreePOPs.
--
-- param pstate is the userdata to pass to (set|get)_popstate_* functions
-- param username is the mail account name
-- param password is the account password
-- param msg is the message number to operate on (may be decreased dy 1)
-- param pdata is an opaque data for popserver_callback(buffer,pdata)
--
-- return POPSERVER_ERR_*
--
-- ************************************************************************** --

-- Is called to initialize the module
function init(pstate)
	freepops.export(pop3server)

	log.dbg("FreePOPs plugin '"..
		PLUGIN_NAME.."' version '"..PLUGIN_VERSION.."' started!\n")

	require("serial") -- the serialization module
	require("browser") -- the browser module
	require("common") -- the common implementation module
	require("mimer") -- the mimer module

	-- checks on globals
	freepops.set_sanity_checks()

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Must save the mailbox name
function user(pstate,username)
	local domain = freepops.get_domain(username)
	local name = freepops.get_name(username)
	
	supereva_globals.username = name .. "@" .. domain
	
	-- parameter to skip cur/ and get only new/
	supereva_globals.onlynew = 
		(freepops.MODULE_ARGS or {}).onlynew ~= nil
		
	return POPSERVER_ERR_OK
end

-- ------------------------------------------------------------------------ --
-- Login helper
function supereva_login()
	if supereva_globals.login_done then
		return POPSERVER_ERR_OK
	end
	
	-- create a new browser
	local b = browser.new()
	-- store the browser object in globals
	supereva_globals.browser = b
  	--b:verbose_mode()
	
  	local post_uri = string.format(strings.login_url,
		supereva_globals.username,supereva_globals.password)

	-- post it
	local file,err = nil, nil
	file,err = supereva_globals.browser:get_uri(post_uri)

	if file == nil then
		log.error_print(err or "unknown error")
		return POPSERVER_ERR_NETWORK
	end
	
  	-- print("we received this webpage: ".. file)
	-- search the session ID
	-- local id = string.find(file,"Benvenuto nella tua webMail")
	local id = string.find(file,"logout.chm")
	
	if id == nil then
		local cause = string.match(file,"ATTENZIONE:([A-Za-z%s]-)<")
		log.error_print(cause or "Unable to catch error details")
		return POPSERVER_ERR_AUTH
	else
		log.say("Session started for " .. supereva_globals.username)
		supereva_globals.login_done = true
	end

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Must login
function pass(pstate,password)
	supereva_globals.password = password
	
	-- eventually load session
	local s = session.load_lock(key())

 	-- check if loaded properly
	if s ~= nil then
		-- "\a" means locked
		if s == "\a" then
			log.say("Session for "..supereva_globals.username..
				" is already locked\n")
			return POPSERVER_ERR_LOCKED
		end
	
		-- load the session
		local c,err = loadstring(s)
		if not c then
			log.error_print("Unable to load saved session: "..err)
			return supereva_login()
		end
		
		-- exec the code loaded from the session string
		c()

		log.say("Session loaded for " .. 
			supereva_globals.username .. "\n")
		
		return POPSERVER_ERR_OK
	else
		-- call the login procedure 
		return supereva_login()
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
	local post_uri = "http://".. supereva_globals.browser:wherearewe() .. 
		"/cgi-bin/del_mov.cgi"
	local post_data = ""

	-- here we need the stat, we build the uri and we check if we
	-- need to delete something
	local delete_something = false;

	local conta=0
	for i=1,get_popstate_nummesg(pstate) do
		if get_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE) then
			post_data = post_data .. "&MSG"..conta.. "=" ..
				get_stat_mapping(get_mailmessage_uidl(pstate,i))
			delete_something = true
			conta=conta+1
		end
	end

	if delete_something then
  		post_data="mailfolder=in&max_msg="..conta..post_data..
			"&pldelete=Delete&tobox=sent"
	      	--post_data = string.gsub(post_data,"new","cur")
	      	local file,err = 
			supereva_globals.browser:post_uri(post_uri,post_data)

		if file == nil then
			log.error_print(err or "unknown error")
			return POPSERVER_ERR_NETWORK
		end
	end
	
	-- save fails if it is already saved
	session.save(key(),serialize_state(),session.OVERWRITE)
	-- unlock is useless if it have just been saved, but if we save 
	-- without overwriting the session must be unlocked manually 
	-- since it would fail instead overwriting
	session.unlock(key())

	log.say("Session saved for " .. supereva_globals.username .. "\n")
	
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Fill the number of messages and their size
function stat(pstate)

	if supereva_globals.stat_done == true then return POPSERVER_ERR_OK end
	
	local pagina = 1
	local uri
	local file,err = nil, nil
	local conta=0
	local fine = nil
	--local b = supereva_globals.browser

	repeat
		-- show browser state
		--supereva_globals.browser:show()

		uri = string.format(strings.first,pagina)
		file,err = supereva_globals.browser:get_uri(uri)

		if file == nil then
			log.error_print(err or "unknown error")
			return POPSERVER_ERR_NETWORK
		end
		
		-- call twice on first page since there is an hidden link
		fine = string.find(file,string.format(strings.next_page,pagina+1))
		if fine ~= nil and pagina == 1 then
			fine = string.find(string.sub(file,fine+1,-1),string.format(strings.next_page,pagina+1))
		end
		
		-- params for mlex (inbox)
		local e = ".*<tr>.*<td>.*<input>.*</td>.*<td>.*</td>.*<td>[.*]{div}[.*]{b}.*{/b}[.*]"..
			"<a>.*<script>.*</script>.*</a>[.*]{/div}.*</td>.*<td>.*</td>.*"..
			"<td>.*</td>.*<td>[.*]{img}.*</td>.*<td>.*</td>.*</tr>"

		local g = "<O>O<O>O<X>O<O>O<O>O<O>O<O>[O]{O}[O]{O}O{O}[O]<O>O<O>O<O>O<O>[O]{O}O"..
			"<O>O<O>O<O>O<O>O<O>O<O>[O]{O}O<O>O<O>X<O>O<O>"

		local x = mlex.match(file,e,g)

		-- increment message number 
		if supereva_globals.onlynew then
			-- we will increase nummesg later
		else
  			-- print("\nmessaggi: "..x:count().."\n")
			set_popstate_nummesg(pstate,x:count()+conta)
		end
	
		-- set uidl/size for each message
		for i=1,x:count() do
			local size = string.match(x:get(1,i-1),"(%d+)")
			local size_mult_k = 
				string.match(x:get(1,i-1),"([Kk])")
			local size_mult_m = 
				string.match(x:get(1,i-1),"([Mm])")
			local uidl = 
				string.match(x:get(0,i-1),'value="([^"]*)"')

			if size_mult_k ~= nil then
				size = size * 1024
			end
			if size_mult_m ~= nil then
				size = size * 1024 * 1024
			end

			-- add only new/ mails or bot new/ and cur/
			if supereva_globals.onlynew then
				local x = string.match(uidl,"^(new)")
				if x ~= nil then
					local num = get_popstate_nummesg(pstate)
					num = math.max ( num , 0 )
					set_popstate_nummesg(pstate,num+1)
					set_mailmessage_size(pstate,num+1,size)
					set_mailmessage_uidl(pstate,num+1,uidl)
				end
			else
				set_mailmessage_size(pstate,i+conta,size)
				local uidl_new=string.gsub(uidl,"new","cur")
				stat_mapping[uidl_new] = uidl
				set_mailmessage_uidl(pstate,i+conta,uidl_new)
			end				
		end -- fox i=1,x:count()
	
		conta=get_popstate_nummesg(pstate)
		-- print ("conta: ",conta)
		pagina=pagina+1
		--print("continuare? ",fine)
		
	until fine == nil

	supereva_globals.stat_done = true
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

function top(pstate,msg,lines,pdata)
	local head,body,body_html,attach = supereva_parse_webmessage(pstate,msg)
	local b = supereva_globals.browser
	local global = common.new_global_for_top(lines,nil)
	local cb = mimer.callback_mangler(common.top_cb(global,pdata,true))
	mimer.pipe_msg(
		head,body,body_html,
		"http://" .. b:wherearewe(),attach,b,cb,nil,"utf-8")

	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Get message msg, must call
-- popserver_callback to send the data
function retr(pstate,msg,data)
	local head,body,body_html,attach = supereva_parse_webmessage(pstate,msg)
	local b = supereva_globals.browser
	local cb = mimer.callback_mangler(common.retr_cb(data))
	mimer.pipe_msg(
		head,body,body_html,
		"http://" .. b:wherearewe(),attach,b,cb,nil,"utf-8")

	return POPSERVER_ERR_OK
end

-- ------------------------------------------------------------------------- --
-- helper
function supereva_parse_webmessage(pstate,msg)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end

	-- some local stuff
	local b = supereva_globals.browser

	-- build the uri
	local uidl = get_stat_mapping(get_mailmessage_uidl(pstate,msg))
	local uri = string.format(strings.get_url,  uidl)

	-- get the main mail page
	local f,rc = b:get_uri(uri)

	-- now it is in cur/ so we hack the mapping 
	stat_mapping[get_mailmessage_uidl(pstate,msg)] = 
		string.gsub(get_mailmessage_uidl(pstate,msg),"new","cur")

	local body_begin_text = '<div id="mailbody" class="mailtext">'
	local body_end_text = '</div><!%-%- google_ad_section_end %-%-></td>'
		
	-- extract the body
	local body_pre_begin, body_begin = string.find(f,body_begin_text)
	local body_end, body_end_post = string.find(f,body_end_text)
	
	local body = string.sub(f,body_begin+1,body_end-1)
	-- mostly useless, just reduces range for mlex
	local attach = string.sub(f,body_end_post+1,-1)

	-- print("--- mail body ---\n"..body.."\n--- end body ---\n")
	
	-- extracts the attach list
	local attach_mdata = '<table class="attachment">.*<tr>.*<td>.*<b>.*</b>.*</td>.*</tr>.*'..
		'<tr>.*<td>.*<a>.*</a>.*<A>.*<img>.*</a>.*<br>.*<b>.*</b>.*<br>.*'..
		'<br>.*</td>.*<td>.*<A>.*</a>.*<br>.*<br>.*<a>.*</a>.*<sup>.*</sup>.*'..
		'<br>.*<br>.*<a>.*</a>.*<br>.*</td>.*</tr>.*</table>'
	
	local attach_mexp = "<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<X>O<O>O<O>O<O>O"..
		"<O>X<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O"..
		"<O>O<O>O<O>O<O>O<O>O<O>O<O>"
	
	-- retrieve the attachments' url list
	local x = mlex.match(attach,attach_mdata,attach_mexp)
	
	local n = x:count()
	local attachments = {}
	for i = 0,n-1 do
    		local url = string.match(x:get(0,i),'HREF=..([^"]*)"')
		url = string.gsub(url,"&amp;", "&")
		-- print("\nattachments:"..n.."http://" .. b:wherearewe().."/" .. url)
		-- attachments[] = "http://" .. b:wherearewe().."/" .. url
		attachments[x:get(1,i)] = "http://" .. b:wherearewe().."/" .. url
		-- table.insert(attachments, "http://"..b:wherearewe().."/"..url)
	end
	--[[
	print("--- "..#attachments)	
	for k,v in pairs(attachments) do print(k,v) end
	print("--- "..#attachments)
	table.foreach(attachments, print)
		print("--- "..#attachments)
	table.foreach(attachments, function(k,v) print(k,v) end)
	]]
	-- mangles the body
	-- local body,body_html = mangle_body(body)
	local body_html = body
	local body = nil

	-- extracts the important part
	local _,head_begin = string.find(f,"<!%-%-Corpo Leggi messaggio%-%->")

	local raw_head = string.sub(f,head_begin,body_pre_begin)
	
	-- print("--- mail head ---\n"..raw_head.."\n--- end head ---")

	-- mangles the header
	local head = mangle_head(raw_head)

	return head,body,body_html,attachments
end

-- ------------------------------------------------------------------------- --
-- helper
function mangle_body(s)
	
	local x = string.match(s,"^%s*(<[Pp][Rr][Ee]>)")

	if x ~= nil then
		local base = "http://" .. supereva_globals.browser:wherearewe()
		s = mimer.html2txtmail(s,base)
		return s,nil
	else

		--s = mimer.remove_lines_in_proper_mail_header(s,
	       	--{"content%-type",
	      	--"content%-disposition","mime%-version"})

		-- the webmail damages these tags
		s = mimer.remove_tags(s,
			{"html","head","body","doctype","void","style"})

--		s = squirrelmail_string.html_preamble .. s ..
--			squirrelmail_string.html_conclusion

		return nil,s
	end
end

-- ------------------------------------------------------------------------- --
-- given the HTML piece with the header, this returns the *clean* mail header
--
function mangle_head(s)
  
	-- helper #1 - extract a header field from HTML
	local function extract(field,data)
		local exM = ".*<td>.*<b>%s</b>.*</td>.*<td>.*<.*>"
		local exG = "O<O>O<O>O<O>O<O>O<O>X<O>"
		local x = mlex.match(data,string.format(exM,field),exG)
		--x:print()
		if x:count() < 1 then
			return nil
		else
			local s = x:get(0,0)
			s = string.gsub(s,"%s+"," ")
			s = string.gsub(s,"\r","")
			s = string.gsub(s,"\n","")
			s = string.gsub(s,"&lt;","<")
			s = string.gsub(s,"&gt;",">")
			s = string.gsub(s,"&nbsp;","")
			return s
		end
	end

	-- helper #2 - translate the date back to english
	local function translate(data)
		data=string.gsub(data,"Gen","Jan")
		data=string.gsub(data,"Mag","May")
		data=string.gsub(data,"Giu","Jun")
		data=string.gsub(data,"Lug","Jul")
		data=string.gsub(data,"Ago","Aug")
		data=string.gsub(data,"Set","Sep")
		data=string.gsub(data,"Ott","Oct")
		data=string.gsub(data,"Dic","Dec")
		return data
	end

	-- helper #3 - build the header
	local function build(to,oggetto,from,cc,data)
		local s = ""
		if to ~= nil then s = s .. "To: "..to end
		if oggetto ~= nil then s = s .. "\nSubject: "..oggetto end
		if from ~= nil then s = s .. "\nFrom: "..from end
		if cc ~= nil then s = s .. "\nCC: "..cc end
		if data ~= nil then s = s .. "\nDate: "..data  end
		return s
	end
	
	-- here we are, now do the job
	
	-- extract all interesting fields
	local from 	= extract("^Da:",s) or ""
	local to 	= extract("^A:",s) or ""
	local cc 	= extract("^CC:",s) or ""
	local data 	= extract("^Data:",s) or ""
	local oggetto 	= extract("^Oggetto:",s) or ""

	-- magle them
	data = translate(data)
	
	-- build the header
	s = build(to,oggetto,from,cc,data)

	-- not sure it is needed
	s = mimer.remove_tags(s,{"tt","nobr","a"})

	-- ??
	s = mimer.txt2mail(s)

	-- go!
	return s
end

-- EOF
-- ************************************************************************** --
