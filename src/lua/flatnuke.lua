-- ************************************************************************** --
--  FreePOPs flatnuke xml news interface
--  
--  $Id$
--  
--  Released under the GNU/GPL license
--  Written by Simone Vellei <simone_vellei@users.sourceforge.net>
-- ************************************************************************** --

-- these are used in the init function
PLUGIN_VERSION = "0.0.1"
PLUGIN_NAME = "flatnuke"

-- Configuration:
--
-- Username must be ".....@flatnuke"
-- Password must be a flatnuke portal URI "http://flatnuke.sourceforge.net"
-- 
-- STAT takes URI/misc/backend.rss the RSS index file 
-- and count the message number, uidl is the news timestamp.
-- RETR takes URI/news/UIDL.xml, the news is in XML format:
-- <!ELEMENT fn:news (fn:title, fn:avatar, fn:reads, fn:header, fn:body, fn:comments?)>
-- <!ATTLIST fn:news
-- xmlns:fn CDATA #FIXED "http://flatnuke.sourceforge.net/news">
-- <!ELEMENT fn:title #PCDATA>
-- <!ELEMENT fn:avatar #PCDATA>
-- <!ELEMENT fn:reads #PCDATA>
-- <!ELEMENT fn:header #PCDATA>
-- <!ELEMENT fn:body #PCDATA>
-- <!ELEMENT fn:comments (fn:comment)+>
-- <!ELEMENT fn:comment (fn:by,fn:post)>
-- <!ELEMENT fn:by #PCDATA>
-- <!ELEMENT fn:post #PCDATA>
--
-- We take the header and body news filed to mail message body and the title to
-- mail subject.

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

local flatnuke_string = {
	-- This is the news title
	titleC = "<fn:title>(.*)</fn:title>",
	-- This is the news header
	headerC = "<fn:header>(.*)</fn:header>",
	-- This is the ews body
	bodyC = "<fn:body>(.*)</fn:body>",
	-- This identify an RSS item
	itemE = "<item rdf:about=\".*\">",
	-- This is the mlex expression to choos the item field
	itemM = "<X>"
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
-- Serialize the internal_state
--
-- serial. serialize is not enough powerfull to correcly serialize the 
-- internal state. the problem is the field b. b is an object. this means
-- that is a table (and no problem for this) that has some field that are
-- pointers to functions. this is the problem. there is no easy way for the 
-- serial module to know how to serialize this. so the hack is: instead of 
-- a function pointer we put a "\a" marked string that tells the serialize 
-- module how to store properly the function pointer. This is donw through 
-- the getf function of the browser class that returns the function pointer 
-- for the function passed as the argument
--
function serialize_state()
	-- XXX FIX XXX --
	-- disty hack for serial, if a string starts with \a (bell)
	-- it is not written with " and this means that the object
	-- members functions will be saved correctly
	internal_state.stat_done = false;
	table.foreach(internal_state.b, function (a,b)
		if type(b) == "function" then
			internal_state.b[a] = "\a".."browser.getf('"..a.."')"
		end
	end)
	serial.init()
	serial.serialize("internal_state",internal_state)

	return serial.OUTPUT
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
	--local site = libero_domain[domain].website
	--local choice = libero_domain[domain].choice
	local user = internal_state.name
	if internal_state.domain ~= "libero.it" then
		user = user .. "@" .. domain
	end
	local x,y = math.mod(os.time(),16),math.mod(os.time()*2,16)
	
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
	--local extract_f = support.do_extract(
	--	internal_state,"session_id",libero_string.sessionC)
	--local check_f = support.check_fail
	--local retrive_f = support.retry_n(
	--	3,support.do_retrive(internal_state.b,uri))

	-- maybe implement a do_once
	--if not support.do_until(retrive_f,check_f,extract_f) then
		-- not sure that it is a password error, maybe a network error
		-- the do_until will log more about the error before us...
		-- maybe we coud add a sanity_check function to do until to
		-- check if the received page is a server error page or a 
		-- good page.
	--	log.error_print("Login failed\n")
	--	return POPSERVER_ERR_UNKNOWN
	--end

	-- check if do_extract has correctly extracted the session ID
	--if internal_state.session_id == nil then
	--	log.error_print("Login failed, unable to get session ID\n")
	--	return POPSERVER_ERR_AUTH
	--end
		
	-- save all the computed data
	--internal_state.popserver = "wpop" .. popnumber .. site
	internal_state.login_done = true
	
	-- log the creation of a session
	--log.say("Session started for " .. internal_state.name .. "@" .. 
	--	internal_state.domain .. 
	--	"(" .. internal_state.session_id .. ")\n")

	return POPSERVER_ERR_OK
end

--------------------------------------------------------------------------------
-- The callbach factory for top and retr
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
-- ended sucesfully (read the socket has benn closed correclty). 
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


function html2txt(str)

str=string.gsub(str,"\n","") 
str=string.gsub(str,"\t","") 
str=string.gsub(str,"<[Tt][Rr]>","\n") 
str=string.gsub(str,"</[Tt][Hh]>","\t") 
str=string.gsub(str,"</[Tt][Dd]>","\t") 
str=string.gsub(str,"<[Bb][Rr]>","\n") 
str=string.gsub(str,"<[Uu][Ll]>","\n") 
str=string.gsub(str,"</[Uu][Ll]>","\n\n") 
str=string.gsub(str,"<[Ll][Ii]>","\n\t* ") 
str=string.gsub(str,"<.->","") 

return str

end

function build_date(str)

return(os.date("%a, %d %b %Y %H:%M:%S +0100",str))

end

function build_mail(title,header,body,uidl)

return ("User-Agent: freepops flatnuke-plugin 0.0.1\r\nMIME-Version: 1.0\r\n"..
	"Content-Disposition: inline\r\n"..
	"Content-Type: text/plain;   charset=\"iso-8859-1\"\r\n"..
	"Content-Transfer-Encoding: quoted-printable\r\n"..
	"Message-Id: <"..uidl..">\r\n"..
	"To: "..internal_state.name.."@"..internal_state.domain.."\r\n"..
	"Date: "..build_date(uidl)..
	"\r\nSubject: "..title..
	"\r\nFrom: freepops@flatnuke.plugin\r\n\r\n"..header..
	"\n\n"..body.."\r\n")

end

function factory_cb(lines,data,uidl)
	local a = stringhack.new_str_hack()
	return function(s,err)
		if s then
			if s ~= "" then
				-- fix add a new callback that has 
				-- size instead of \0
				-- that wil be faster in lua XXX
				local _,_,title=string.find(s,
				flatnuke_string.titleC)
				local _,_,header=string.find(s,
				flatnuke_string.headerC)
				header=html2txt(header) 
				local _,_,body=string.find(s,
				flatnuke_string.bodyC)
				body=html2txt(body) 
				s = build_mail(title,header,body,uidl)
				
				if lines ~= nil then
					s = stringhack.tophack(s,lines,a)
				end
				
				s = stringhack.dothack(s,a).."\0"
				
				popserver_callback(s,data)
			else
				-- trasmission ended successfully!
				stringhack.delete_str_hack(a)
				return nil,"EOF"
			end
		else
			log.error_print(err)
			stringhack.delete_str_hack(a)
			return nil,"network error: "..err
		end

		-- check if we need to stop (in top only)
		if lines ~= nil and stringhack.check_stop(lines,a) then
			stringhack.delete_str_hack(a)
			return nil,"EOF"
		else
			return true,nil
		end
	end
end	

-- ************************************************************************** --
--  flatnuke functions
-- ************************************************************************** --

-- Must save the mailbox name
function user(pstate,username)
	
	-- extract and check domain
	local domain = get_domain(username)
	local name = get_name(username)

	-- save domain and name
	internal_state.domain = domain
	internal_state.name = name
	
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Must login
function pass(pstate,password)
	-- save the password
	-- password is the flatnuke URI basename
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

		--log.say("Session loaded for " .. internal_state.name .. "@" .. 
		--	internal_state.domain .. 
		--	"(" .. internal_state.session_id .. ")\n")
		
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
	--local popserver = internal_state.popserver
	--local session_id = internal_state.session_id
	--local b = internal_state.b

	--local uri = string.format(libero_string.delete,popserver,session_id,
	--	get_popstate_nummesg(pstate))

	-- here we need the stat, we build the uri and we check if we 
	-- need to delete something
	--local delete_something = false;
	
	--for i=1,get_popstate_nummesg(pstate) do
	--	if get_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE) then
	--		uri = uri .. string.format(libero_string.delete_next,
	--			i,get_mailmessage_uidl(pstate,i))
	--		delete_something = true	
	--	end
	--end

	--if delete_something then
		-- Build the functions for do_until
	--	local extract_f = function(s) return true,nil end
	--	local check_f = support.check_fail
	--	local retrive_f = support.retry_n(3,support.do_retrive(b,uri))

	--	if not support.do_until(retrive_f,check_f,extract_f) then
	--		log.error_print("Unable to delete messages\n")
	--		return POPSERVER_ERR_UNKNOWN
	--	end
	--end

	-- save fails if it is already saved
	session.save(key(),serialize_state(),session.OVERWRITE)
	-- unlock is useless if it have just been saved, but if we save 
	-- without overwriting the session must be unlocked manually 
	-- since it wuold fail instead overwriting
	session.unlock(key())

--	log.say("Session saved for " .. internal_state.name .. "@" .. 
--		internal_state.domain .. "(" .. 
--		internal_state.session_id .. ")\n")

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
	--local popserver = internal_state.popserver
	--ocal session_id = internal_state.session_id
	local b = internal_state.b

	-- this string will contain the uri to get. it may be updated by 
	-- the check_f function, see later
	local uri = internal_state.password.."/misc/backend.rss\n"
	
	-- uses mlex to extract all the messages uidl and size
	local function action_f (s) 
		-- calls match on the page s, with the mlexpressions
		-- statE and statG
		local x = mlex.match(s,flatnuke_string.itemE,flatnuke_string.itemM)
		
		-- the number of results
		local n = mlex.count(x)

		if n == 0 then
			mlex.free(x)
			return true,nil
		end

		-- this is not really needed since the structure 
		-- grows automatically... maybe... don't remember now
		local nmesg_old = get_popstate_nummesg(pstate)
		local nmesg = nmesg_old + n
		set_popstate_nummesg(pstate,nmesg)

		-- gets all the results and puts them in the popstate structure
		for i = 1,n do
			local uidl = mlex.get (0,i-1,x,s) 
	--		local size = mlex.get (1,i-1,x,s)

			-- arrange message size
			local k = nil
	--		_,_,k = string.find(size,"([Kk][Bb])")
	--		_,_,size = string.find(size,"(%d+)")
	--		
	--		fucking default size
			size=1000
			_,_,uidl = string.find(uidl,".*/(%d+)")
			--size = tonumber(size) + 2
			--if k ~= nil then
			--	size = size * 1024
			--end

			if not uidl or not size then
				mlex.free(x)
				return nil,"Unable to parse page"
			end

			-- set it
			set_mailmessage_size(pstate,i+nmesg_old,size)
			set_mailmessage_uidl(pstate,i+nmesg_old,uidl)
		end
		
		mlex.free(x)

		return true,nil
	end

	-- check must control if we are not in the last page and 
	-- eventually change uri to tell retrive_f the next page to retrive
	local function check_f (s)  
		--local tmp1,tmp2 = string.find(s,libero_string.next_checkC)
		--return true
		--if tmp1 ~= nil then
			-- change retrive behaviour
		--	uri = string.format(libero_string.next,
		--		popserver,session_id)
			-- continue the loop
		--	return false
		--else
			return true
		--end
	end

	-- this is simple and uri-dependent
	local function retrive_f ()  
		print("---->" .. uri)
		return b:get_uri(uri)
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
	
	local uidl = get_mailmessage_uidl(pstate,msg)
	-- the callback
	local cb = factory_cb(nil,data,uidl)
	
	-- some local stuff
	local popserver = internal_state.popserver
	local session_id = internal_state.session_id
	local b = internal_state.b
	
	-- build the uri
	local uri = internal_state.password.."/news/"..uidl..".xml"
	
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
	local uri = internal_state.password.."/news/"..uidl..".xml"
	-- the callback
	local cb = factory_cb(lines,data,uidl)
	
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
