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
PLUGIN_VERSION = "0.0.4"
PLUGIN_NAME = "RSS/RDF aggregator"
PLUGIN_REQUIRE_VERSION = "0.0.14"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://freepops.org/download.php?file=aggregator.lua"
PLUGIN_HOMEPAGE = "http://freepops.org/"
PLUGIN_AUTHORS_NAMES = {"Simone Vellei"}
PLUGIN_AUTHORS_CONTACTS = {"simone_vellei@users.sourceforge.net"}
PLUGIN_DOMAINS = {"@aggrefator","..."}
PLUGIN_PARAMETERS = {}
PLUGIN_DESCRIPTIONS = {
	it= [[
Solitamente potete trarre beneficio dal for mato RSS del W3C quando leggete
news da qualche sito web. Il file RSS indicizza le news, fornendo un 
link verso di esse. Questo plugin pu&ograve; far s&igrave; che il vostro 
client di posta veda il file RSS come una mailbox da cui potete 
scaricare ogni news come se fosse una mail. L'unica limitazione 
&egrave; che questo plugin pu&ograve; prelevare solo un sunto delle news
pi&ugrave; il link alle news. 
Per usare questo plugin dovete usare un nome utente casuale con il 
suffisso @aggregator (es.: foo@aggregator) e come password l'URL del file RSS
(es.: http://www.securityfocus.com/rss/vulnerabilities.xml). Per 
comodit&agrave; abbiamo aggiunto per voi alcuni alias. 
Questo significa che non dovrete cercare a mano l'URL del file RSS. 
Abbiamo aggiunto alcuni domini, per esempio 
@securityfocus.com, che possono essere usati per sfruttare direttamente
il plugin aggregator con questi siti web. Per usare questi alias dovrete usare
un nome utente nella for ma qualcosa@aggregatordomain e una password a
caso.]],
	en= [[
Usually you can benefit from the W3C's RSS for mat when you read some 
website news. The RSS file indexes the news, 
providing a link to them. This plugin
can make your mail client see the RSS file as a mailbox from which you can
download each news as if it was a mail message. The only limitation is that
this plugin can fetch only a news summary plus the news link.
To use this plugin you have to use a casual user name with the @aggregator
suffix (ex: foo@aggregator) and as the password the URL of the RSS file(ex:
http://www.securityfocus.com/rss/vulnerabilities.xml). For your 
commodity we added some alias for you. This means you have not to search by
hand the URL of the RSS file. We added some domain, 
for example @securityfocus.com,
that can be used to directly use the aggregator plugin with these website. To
use these alias you have to use a user name in the form 
something@aggregatordomain
and a casual password.]],
}

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
-- (read sprintf) arguments, so their %s and %d are filled properly
-- 
-- C, E, G are postfix respectively to Captures (lua string pcre-style 
-- expressions), mlex expressions, mlex get expressions.
-- 

local rss,charset

local rss_string = {
	charsetC = "xml version=\"[^\"]*\" encoding=\"([^\?]*)\"",
	item_bC = "<item",
	item_eC = "</item>",
	itemC = "(</item>)",
	linkC = "<link.*>(.*)</link>",
	link2C = "<guid.*>(.*)</guid>",
	titleC = "<title.*>(.*)</title>",
--	title2C = "<title.*>[<]?[!]?[\[]?C?D?A?T?A?[\[]?([^\]]*).*[>]?</title.*>",
	title2C = "<title.*>[<]?[!]?[\[]([^\]]*).*[>]?</title>",
	descC = "<desc.*>(.*)</desc.*>",
	desc2C = "<desc.*>[<]?[!]?[\[]([^\]]*).*[>]?</desc.*>",
	contentC = "<content.*>[<]?[!]?[\[]([^\]]*).*[>]?</content.*>",
--	desc2C = "<desc.*>[<]?[!]?[\[]?C?D?A?T?A?[\[]?([^\]]*).*[>]?</desc.*>",
	dateC = "<pubDate.*>(.*)</pubDate.*>"
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
	str=string.gsub(str,"\r","") 
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
	str=string.gsub(str,"&gt;",">") 
	str=string.gsub(str,"&lt;","<")
	str=string.gsub(str,"<a href=\"([^\"]*)\"[^>]*>([^<]*)</a>","%2 (%1)")
	str=string.gsub(str,"</p>","\n")
	

	str=string.gsub(str,"<.->","") 
	
	
	return str
end

--------------------------------------------------------------------------------
-- Build a mail header date string
--
function build_date(str)
	if(str==nil) then
		return(os.date("%a, %d %b %Y %H:%M:%S"))
	else
		return(str)
	end	
end

--------------------------------------------------------------------------------
-- Build a mail header
--
function build_mail_header(title,uidl,mydate)
	return 
	"Message-Id: <"..uidl..">\r\n"..
	"To: "..internal_state.name.."@"..internal_state.password.."\r\n"..
	"Date: "..build_date(mydate).."\r\n"..
	"Subject: "..title.."\r\n"..
	"From: freepops@"..internal_state.password.."\r\n"..
	"User-Agent: freepops "..PLUGIN_NAME..
		" plugin "..PLUGIN_VERSION.."\r\n"..
	"MIME-Version: 1.0\r\n"..
	"Content-Disposition: inline\r\n"..
	"Content-Type: text/plain;   charset=\""..charset.."\"\r\n"..
	-- This header cause some problems with link like [...]id=123[...]
	-- "Content-Transfer-Encoding: quoted-printable\r\n"..
	"\r\n"..
	"News link:\r\n"
end

--------------------------------------------------------------------------------
-- retr and top aree too similar. discrimitaes only if lines ~= nil
--
function retr_or_top(pstate,msg,data,lines)
	-- we need the stat
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end
	
	local uidl = get_mailmessage_uidl(pstate,msg)
	

	--get it
	
	local s2=rss
	local starts2
	local ends2
	local chunk
	
	for i=1,msg do
		starts2,_,_=string.find(s2,rss_string.item_bC);
                ends2,_,_=string.find(s2,rss_string.item_eC);
		chunk=string.sub(s2,starts2,ends2)
		s2=string.sub(s2,ends2+3)
	end
									
	local _,_,title=string.find(chunk,rss_string.titleC)
	if ((title == nil) or (title == "")) then
		 _,_,title=string.find(chunk,rss_string.title2C)
		title=string.gsub(title,"CDATA%[","");
	end
	local _,_,header=string.find(chunk,rss_string.linkC)
	if ((header == nil) or (header == "")) then
		_,_,header=string.find(chunk,rss_string.link2C)
	end
	
	local _,_,body=string.find(chunk,rss_string.descC)
	if ((body == nil) or (body == "")) then
		_,_,body=string.find(chunk,rss_string.desc2C)
		if(body ~= nil) then
 			body=string.gsub(body,"CDATA%[","")
		end
	end

	--this is enabled in 
	-- xmlns:content="http://purl.org/rss/1.0/modules/content/"
	local _,_,content=string.find(chunk,rss_string.contentC)
	-- content contains description
	if ((content ~= nil) and (body ~= nil)) then
		body=content
 		body=string.gsub(body,"CDATA%[","")
	end
	
	local _,_,mydate=string.find(chunk,rss_string.dateC)

	if (body == nil) then
		body="Not available"
	end

	if header == nil or body == nil or title == nil then
		log.error_print("Error parsing: title="..
			(title or "nil").." header="..
			(header or "nil").." body="..(body or "nil"))
	end

	--clean it
	header=string.gsub(header,"&amp;","&");
	title=html2txt(title)
	body=html2txt(body)


	--build it
	local s = build_mail_header(title,uidl,mydate) .. 
		header .. "\r\n\r\n" .. 
		"News description:\r\n"..
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
	if (freepops.MODULE_ARGS ~= nil) then
		if freepops.MODULE_ARGS.host ~= nil then
        	        internal_state.password = freepops.MODULE_ARGS.host
		else
			internal_state.password = password
		end
	end

	
	if(string.find(internal_state.password,"http://") == nil) then
		 log.error_print("Not a valid URI: "..internal_state.password.."\n")
		 return POPSERVER_ERR_NETWORK
	end
						 
	-- build the uri
	local user = internal_state.name
	
	-- the browser must be preserved
	internal_state.b = browser.new()
--	b:verbose_mode()
	
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
-- Fill the number of messages and their size
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
		rss=s
		_,_,charset=string.find(rss,rss_string.charsetC)
		local a=0
		local start=0
		local nmess=0
		while(a~=nil) do
			start,_,a=string.find(s,rss_string.itemC,start+1);
			if(a~=nil) then
				nmess=nmess+1
			end
			
		end
		local n=nmess	
		
		-- this is not really needed since the structure 
		-- grows automatically... maybe... don't remember now
		set_popstate_nummesg(pstate,nmess)

		-- gets all the results and puts them in the popstate structure
		local s2=s
		local starts2
		local ends2
		for i = 1,n do
			starts2,_,_=string.find(s2,rss_string.item_bC);
			ends2,_,_=string.find(s2,rss_string.item_eC);
			local chunk=string.sub(s2,starts2,ends2)
			s2=string.sub(s2,ends2+3)
			
			local _,_,uidl = string.find(chunk,rss_string.linkC)
			if ((uidl == nil) or (uidl=="")) then
				 _,_,uidl = string.find(chunk,rss_string.link2C)
			end
			--fucking default size
			local size=2048

			if not uidl or not size then
				return nil,"Unable to parse uidl"
			end

			-- set it
			set_mailmessage_size(pstate,i,size)
			uidl=base64.encode(uidl)
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
-- Do nothing
function noop(pstate)
	return common.noop(pstate)
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
