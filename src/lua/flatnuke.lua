-- --------------------------- READ THIS PLEASE ----------------------------- --
-- This file is not only the flatnuke webnews plugin. Is is also a well 
-- documented example of webnews plugin. 
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
--   and count the message number, uidl is the news timestamp.
-- RETR takes URI/news/UIDL.xml, the news is in XML format:
-- 
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
-- 

-- ************************************************************************** --
--  strings
-- ************************************************************************** --

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
	itemG = "<X>"
}


-- ************************************************************************** --
--  State
-- ************************************************************************** --

-- this is the internal state of the plugin. This structure will be serialized 
-- and saved to remember the state.
internal_state = {
	stat_done = false,
	login_done = false,
	domain = nil,
	name = nil,
	password = nil,
	b = nil
}

-- ************************************************************************** --
--  Helpers functions
-- ************************************************************************** --

--------------------------------------------------------------------------------
-- Extracts the account name of a mailaddress
--
function get_name(s)
	local _,_,d = string.find(s,"([_%.%a%d]+)@[_%.%a%d]+")
	return d
end

--------------------------------------------------------------------------------
-- Converts HTML news tag into text
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

--------------------------------------------------------------------------------
-- Build a mail header date string
--
function build_date(str)
	return(os.date("%a, %d %b %Y %H:%M:%S +0100",str))
end

--------------------------------------------------------------------------------
-- Build a mail header
--
function build_mail_header(title,uidl)
	return 
	"Message-Id: <"..uidl..">\r\n"..
	"To: "..internal_state.name.."@"..internal_state.password.."\r\n"..
	"Date: "..build_date(uidl).."\r\n"..
	"Subject: "..title.."\r\n"..
	"From: freepops@"..internal_state.password.."\r\n"..
	"User-Agent: freepops "..PLUGIN_NAME..
		" plugin "..PLUGIN_VERSION.."\r\n"..
	"MIME-Version: 1.0\r\n"..
	"Content-Disposition: inline\r\n"..
	"Content-Type: text/plain;   charset=\"iso-8859-1\"\r\n"..
	"Content-Transfer-Encoding: quoted-printable\r\n"..
	"\r\n"
end

--------------------------------------------------------------------------------
-- retr and top aree too similar. discrimitaes only if lines ~= nil
--
function retr_or_top(pstate,msg,data,lines)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end
	
	local uidl = get_mailmessage_uidl(pstate,msg)
	
	--some locals
	local b = internal_state.b
	
	-- build the uri
	local uri = "http://"..internal_state.password.."/news/"..uidl..".xml"
	
	-- tell the browser to get the uri
	local s,rc = b:get_uri(uri)

	--check it
	if s == nil then
		log.error_print("Asking for "..uri.."\n")
		log.error_print(rc.error.."\n")
		return POPSERVER_ERR_NETWORK
	end

	--get it
	local _,_,title=string.find(s,flatnuke_string.titleC)
	local _,_,header=string.find(s,flatnuke_string.headerC)
	local _,_,body=string.find(s,flatnuke_string.bodyC)

	if header == nil or body == nil or title == nil then
		log.error_print("Error parsing: title="..
			(title or "nil").." header="..
			(header or "nil").." body="..(body or "nil"))
	end

	--clean it
	header=html2txt(header) 
	body=html2txt(body)

	--build it
	s = build_mail_header(title,uidl) .. 
		header .. "\r\n\r\n" .. 
		body.. "\r\n"

	--hack it
	local a = stringhack.new_str_hack()
	if lines ~= nil then
		s = stringhack.tophack(s,lines,a)
	end
	s = stringhack.dothack(s,a)
	stringhack.delete_str_hack(a)
	
	--end it
	s = s .. "\0"
		
	--send it
	popserver_callback(s,data)
	
	return POPSERVER_ERR_OK
end

-- ************************************************************************** --
--  flatnuke functions
-- ************************************************************************** --

-- Must save the mailbox name
function user(pstate,username)
	
	-- extract username
	local name = get_name(username)

	-- save name
	internal_state.name = name
	
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Must login
function pass(pstate,password)
	if internal_state.login_done then
		return POPSERVER_ERR_OK
	end

	-- save the password
	-- password is the flatnuke URI basename
	internal_state.password = password

	-- build the uri
	local user = internal_state.name
	
	-- the browser must be preserved
	internal_state.b = browser.new()
	
	internal_state.login_done = true
	
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Must quit without updating
function quit(pstate)
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Update the mailbox status and quit
function quit_update(pstate)
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
	local uri = "http://"..internal_state.password.."/misc/backend.rss"
	
	-- uses mlex to extract all the messages uidl and size
	local function action_f (s) 
		-- calls match on the page s, with the mlexpressions
		-- statE and statG
		local x = mlex.match(s,flatnuke_string.itemE,
			flatnuke_string.itemG)
		
		-- the number of results
		local n = mlex.count(x)

		if n == 0 then
			mlex.free(x)
			return true,nil
		end

		-- this is not really needed since the structure 
		-- grows automatically... maybe... don't remember now
		set_popstate_nummesg(pstate,n)

		-- gets all the results and puts them in the popstate structure
		for i = 1,n do
			local uidl = mlex.get (0,i-1,x,s) 

			--fucking default size
			size=1000
			_,_,uidl = string.find(uidl,".*/(%d+)")

			if not uidl or not size then
				mlex.free(x)
				return nil,"Unable to parse uidl"
			end

			-- set it
			set_mailmessage_size(pstate,i,size)
			set_mailmessage_uidl(pstate,i,uidl)
		end
		
		mlex.free(x)

		return true,nil
	end

	-- check must control if we are not in the last page and 
	-- eventually change uri to tell retrive_f the next page to retrive
	local  check_f = support.check_fail

	-- this is simple 
	local retrive_f = support.do_retrive(b,uri)

	-- this to initialize the data structure
	set_popstate_nummesg(pstate,0)

	-- do it
	if not support.do_until(retrive_f,check_f,action_f) then
		log.error_print("Stat failed\n")
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
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Mark msg for deletion
function dele(pstate,msg)
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Get first lines message msg lines, must call 
-- popserver_callback to send the data
function retr(pstate,msg,data)
	return retr_or_top(pstate,msg,data)
end

-- -------------------------------------------------------------------------- --
-- Get message msg, must call 
-- popserver_callback to send the data
function top(pstate,msg,lines,data)
	return retr_or_top(pstate,msg,data,lines)
end

-- -------------------------------------------------------------------------- --
--  This function is called to initialize the plugin.
--  Since we need to use the browser we have to use
--  some modules with the dofile function
--
--  We also exports the pop3server.* names to global environment so we can
--  write POPSERVER_ERR_OK instead of pop3server.POPSERVER_ERR_OK.
--  
function init(pstate)
	freepops.export(pop3server)
	
	log.dbg("FreePOPs plugin '"..
		PLUGIN_NAME.."' version '"..PLUGIN_VERSION.."' started!\n")

	-- the browser module
	if freepops.dofile("browser.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end
		
	return POPSERVER_ERR_OK
end

-- EOF
-- ************************************************************************** --
