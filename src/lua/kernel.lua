
-- --------------------------- READ THIS PLEASE ----------------------------- --
-- This file is not only the RSS/RDF aggregator plugin. Is is also a well 
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
--  FreePOPs RSS/RDF aggregator xml news interface
--  
--  $Id$
--  
--  Released under the GNU/GPL license
--  Written by Simone Vellei <simone_vellei@users.sourceforge.net>
-- ************************************************************************** --

-- these are used in the init function
PLUGIN_VERSION = "0.0.1"
PLUGIN_NAME = "kernel.org Changelog viewer"

-- Configuration:
--
-- Username must be ".....@aggregator"
-- Password must be a pointer to RSS/RDF file 
-- Es. "http://flatnuke.sourceforge.net/misc/backend.rss"
-- 
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

local kernel_html
local string_type

local kernel_string = {
	linkE24 =
		"</b>.*<td>.*"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]<a.*2.4.[[:digit:]]+\">Changelog</a>",
	linkE26 =
		"</b>.*<td>.*"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]<a.*2.6.[[:digit:]]+\">Changelog</a>",
	linkE =
		"</b>.*<td>.*"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]{a.*}.*{/a}[.*]"..
		"<td>[.*]<a.*>Changelog</a>",
	linkG = 
		"<O>O<O>X"..
		"<O>[O]{O}O{O}[O]"..
		"<O>[O]{O}O{O}[O]"..
		"<O>[O]{O}O{O}[O]"..
		"<O>[O]{O}O{O}[O]"..
		"<O>[O]<X>O<O>",
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
	str=string.gsub(str,"&amp;","&") 
	str=string.gsub(str,"&agrave;","à") 
	str=string.gsub(str,"&igrave;","ì") 
	str=string.gsub(str,"&egrave;","è") 
	str=string.gsub(str,"&ograve;","ò") 
	str=string.gsub(str,"&quot;","\"") 

	str=string.gsub(str,"<.->","") 
	
	return str
end

--------------------------------------------------------------------------------
-- Build a mail header date string
--
function build_date(str)
	return(os.date("%a, %d %b %Y %H:%M:%S",str))
	
end

--------------------------------------------------------------------------------
-- Build a mail header
--
function build_mail_header(title,uidl)
	return 
	"Message-Id: <"..uidl..">\r\n"..
	"To: "..internal_state.name.."@kernel.org\r\n"..
	"Date: "..build_date(uidl).."\r\n"..
	"Subject: "..title.."\r\n"..
	"From: freepops@kernel.org\r\n"..
	"User-Agent: freepops "..PLUGIN_NAME..
	" plugin "..PLUGIN_VERSION.."\r\n"..
	"MIME-Version: 1.0\r\n"..
	"Content-Disposition: inline\r\n"..
	"Content-Type: text/plain;   charset=\"iso-8859-1\"\r\n"..
	-- This header cause some problems with link like [...]id=123[...]
	-- "Content-Transfer-Encoding: quoted-printable\r\n"..
	"\r\n"
--	"News link:\r\n"
end

--------------------------------------------------------------------------------
-- retr and top aree too similar. discrimitaes only if lines ~= nil
--
function retr_or_top(pstate,msg,data,lines)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end
	
	local uidl = get_mailmessage_uidl(pstate,msg)
	
	local b = internal_state.b
	--uri=string.gsub(uidl,"-","--")
	_,_,uri=string.find(uidl,"UTC(.*)")
	uidl=string.gsub(uidl,uri,"")
	--yyyy-mm-dd hh:mm
	--mm/dd/yyyy hh:mm:ss 
	--azzo=string.gfind(uidl,"(%d*)%-(%d*)%-(%d*)")
	--a=azzo()
--	azzo=string.gfind(uidl,"(%d*)%-(%d*)%-(%d*)")
--	a=azzo()
	--log.say("AZZO "..a)	
	_,_,year=string.find(uidl,"(%d*)%-")
	_,_,month=string.find(uidl,year.."%-(%d*)%-")
	_,_,day=string.find(uidl,year.."%-"..month.."%-(%d*)")
	_,_,hour=string.find(uidl,day.." (%d*):")
	_,_,mins=string.find(uidl,hour..":(%d*)")
	dd=month.."/"..day.."/"..year.." "                           
	..hour..":"..mins..":00"
--	log.say("PRENDO "..dd.."\n")
	
	dd=getdate.toint(dd)
--	log.say("PRENDO "..dd.."\n")
--	b.curl:setopt(OPT_VERBOSE,1)
	
	--local b = browser.new()
	local body = b:get_uri(uri)

	--local s,rc = b:get_uri(uri)
	if body == nil then
		log.error_print("Asking for "..uri.."\n")
		log.error_print(rc.error.."\n")
		return POPSERVER_ERR_NETWORK
	end
									

	--build it
	local _,_,title=string.find(uri,".*/(.*)")
	s = build_mail_header(title,dd) .. 
--		header .. "\r\n\r\n" .. 
--		"News description:\r\n"..
		body.. "\r\n"

	--hack it
	local a = stringhack.new()
	if lines ~= nil then
		s = a:tophack(s,lines)
	end
	s = a:dothack(s,a)
	
	--end it
	s = s .. "\0"
		
	--send it
	popserver_callback(s,data)
	
	return POPSERVER_ERR_OK
end

-- ************************************************************************** --
--  aggregator functions
-- ************************************************************************** --

-- Must save the mailbox name
function user(pstate,username)
	
	-- extract username
	local name = get_name(username)

	-- save name
	internal_state.name = name

	if(name == "linux24") then
		string_type = kernel_string.linkE24
	elseif (name == "linux26") then
		string_type = kernel_string.linkE26
	else
		string_type = kernel_string.linkE
	end	
		
		
		
	
	return POPSERVER_ERR_OK
end

-- -------------------------------------------------------------------------- --
-- Must login
function pass(pstate,password)
	if internal_state.login_done then
		return POPSERVER_ERR_OK
	end

	-- save the password
	-- password is the RSS/RDF file URI 
	if freepops.MODULE_ARGS ~= nil then
	log.say("ARGS "..freepops.MODULE_ARGS.host)
		if(freepops.MODULE_ARGS.host == "24") then
			string_type = kernel_string.linkE24
		elseif (freepops.MODULE_ARGS.host == "26") then
			string_type = kernel_string.linkE26
		end
	end

	internal_state.password = "http://kernel.org"
						
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
	local b = internal_state.b

	-- this string will contain the uri to get. it may be updated by 
	-- the check_f function, see later
	local uri = internal_state.password
	
	-- extract all the messages uidl
	local function action_f (s) 
		--	
		-- sets global var rss
		kernel_html=s
		s=string.gsub(kernel_html,
		"<td>&nbsp;","<td><a href=\"#\">void</a>")
		--print(kernel_html)
		local a=0
		local start=0
		local nmess=0
		local x = mlex.match(s,string_type,kernel_string.linkG)
		
		n=x:count()
		nmess=n
		
		-- this is not really needed since the structure 
		-- grows automatically... maybe... don't remember now
		set_popstate_nummesg(pstate,nmess)

		-- gets all the results and puts them in the popstate structure
		local s2=s
		local starts2
		local ends2
		for i = 1,n do
			strtmp1=string.gsub(x:get(0,i-1),"\n","")
			strtmp2=string.gsub(x:get(1,i-1),"a href=","")
			strtmp2=string.gsub(strtmp2,"\"","")
			--strtmp="http://kernel.org"..strtmp
			--strtmp2="http://zaccheo"..strtmp2
			strtmp2="http://kernel.org"..strtmp2
			strtmp=strtmp1..strtmp2
--			log.say("UIDL "..strtmp.."\n\n")
			
			
			local uidl = strtmp
--			--fucking default size
--			size=3200			
			local b = internal_state.b
			header=b:get_head(strtmp2)
--			body=b:get_uri(strtmp)
--			log.say("["..body.."]")
			local _,_,size=string.find(header,"Content--Length: (%d*)");
--			log.say("["..size.."]")
			
--			size=3200			

			if not uidl or not size then
				return nil,"Unable to parse uidl"
			end

			-- set it
			set_mailmessage_size(pstate,i,size)
			set_mailmessage_uidl(pstate,i,uidl)
		end
		
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
