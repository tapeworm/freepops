-- ************************************************************************** --
--  FreePOPs @yahoo.com webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russell822@yahoo.com>
--  yahoo.it added by Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
--  yahoo.ie added by Bruce Williamson <aztrix@yahoo.com>
--  Contributions by Przemyslaw Wroblewski <przemyslaw.wroblewski@gmail.com>
--  Contributions from Kevin Edwards
-- ************************************************************************** --

-- Globals
--
local _DEBUG = false
local DBG_LEN = nil -- 500

PLUGIN_VERSION = "0.2.1d"
PLUGIN_NAME = "yahoo.com"
PLUGIN_REQUIRE_VERSION = "0.2.0"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://www.freepops.org/download.php?module=yahoo.lua"
PLUGIN_HOMEPAGE = "http://www.freepops.org/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager","Nicola Cocchiaro"}
PLUGIN_AUTHORS_CONTACTS = 
	{"russell822 (at) yahoo (.) com",
         "ncocchiaro (at) users (.) sourceforge (.) net"}
PLUGIN_DOMAINS = {"@yahoo.com", "@yahoo.ie", "@yahoo.it", "@yahoo.ca", "@rocketmail.com", "@yahoo.com.ar",
                  "@yahoo.co.in", "@yahoo.co.id", "@yahoo.com.tw", "@yahoo.co.uk", "@yahoo.com.cn",
                  "@yahoo.es", "@yahoo.de", "@talk21.com", "@btinternet.com", "@yahoo.com.au", "@yahoo.co.nz",
}

PLUGIN_PARAMETERS = {
	{name = "folder", description = {
		it = [[
Viene usato per scegliere la cartella (Inbox &egrave; il 
default) con cui volete interagire. Le cartelle disponibili sono quelle 
standard di Yahoo, chiamate 
Inbox, Draft, Sent, Bulk e 
Trash (per domini yahoo.it potete usare gli stessi nomi per oppure 
quelli corrispondenti in Italiano: InArrivo, Bozza, 
Inviati, Anti-spam, Cestino). Se avete creato delle 
cartelle potete usarle con i loro nomi.]],
		en = [[
Parameter is used to select the folder (Inbox is the default)
that you wish to access. The folders that are available are the standard 
Yahoo folders, called 
Inbox, Draft, Sent, Bulk and 
Trash (for yahoo.it domains you may use the same folder names or the 
corresponding names in Italian: InArrivo, Bozza, 
Inviati,Anti-spam, Cestino). For user defined folders, use their name as the value.]]
		}	
	},
	{name = "view", description = {
		it = [[ Viene usato per determinare la lista di messaggi da scaricare. I valori possibili sono All (tutti), Unread (non letti) e Flag.]],
		en = [[ Parameter is used when getting the list of messages to 
pull.  It determines what messages to be pulled.  Possible values are All, Unread and Flag.]]
		}
	},
	{name = "markunread", description = {
		it = [[ Viene usato per far s&igrave; che il plugin segni come non letti i messaggi che scarica. Se il valore &egrave; 1 questo comportamento viene attivato.]],
		en = [[ Parameter is used to have the plugin mark all messages that it
pulls as unread.  If the value is 1, the behavior is turned on.]]
		}
	},
	{name = "nossl", description = {
		it = [[ Viene usato per forzare il modulo a fare login con HTTP semplice e non HTTPS con SSL. Se il valore &egrave; 1 questo comportamento viene attivato.]],
		en = [[ Parameter is used to force the module to login through plain
HTTP and not HTTPS with SSL.  If the value is 1, the SSL is not used.]]
		}
	},
	{name = "emptytrash", description = {
		it = [[ Viene usato per forzare il plugin a svuotare il cestino quando ha finito di scaricare i messaggi. Se il valore &egrave; 1 questo comportamento viene attivato.]],
		en = [[
Parameter is used to force the plugin to empty the trash folder when it is done
pulling messages.  Set the value to 1.]]
		}	
	},
	{name = "emptybulk", description = {
		it = [[ Viene usato per forzare il plugin a svuotare la cartella AntiSpam quando ha finito di scaricare i messaggi. Se il valore &egrave; 1 questo comportamento viene attivato.]],
		en = [[
Parameter is used to force the plugin to empty the bulk folder when it is done
pulling messages.  Set the value to 1.]]
		}	
	},
	{name = "maxmsgs", description = {
		en = [[
Parameter is used to force the plugin to only download a maximum number of messages. ]]
		}	
	},
}

PLUGIN_DESCRIPTIONS = {
	it=[[
Questo plugin vi per mette di leggere le mail che avete in una 
mailbox con dominio come @yahoo.com, @yahoo.ca o @yahoo.it.
Per usare questo plugin dovete usare il vostro indirizzo email completo come
user name e la vostra password reale come password.]],
	en=[[
This is the webmail support for @yahoo.com, @yahoo.ca and @yahoo.it and similar mailboxes. 
To use this plugin you have to use your full email address as the user 
name and your real password as the password.]]
}

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

local globals = {
  -- Login strings
  --
  strMailPage = "http://mail.yahoo.com",
  strLoginPage = "http://login.yahoo.com",
  strLoginHTTP = "http://login.yahoo.com/config/login",   
  strLoginHTTPs = "https://login.yahoo.com/config/login",   
  strLoginPostData = ".tries=1&.src=ym&.intl=%s&login=%s&passwd=%s&.persistent=y&.v=0&.chkP=Y&.u=%s",
  strLoginPostDataMD5 = ".tries=1&.src=ym&.intl=%s&login=%s&passwd=%s&.hash=1"..
                        "&.md5=1&.js=1&.challenge=%s&.persistent=y&.v=0&.chkP=Y&.u=%s",
  strLoginFailed = "Login Failed - Invalid User name and password",
  strLoginChallenge = 'name="%.challenge" value="([^"]-)"',
  strLoginU = 'name="%.u" value="([^"]-)"',

  -- Expressions to pull out of returned HTML from Yahoo corresponding to a problem
  --
  strRetLoginBadPassword = "(login_form)",
  strRetLoginSessionExpired = "(error code:  Login)",

  -- Regular expression to extract the mail server
  --

  -- Get the mail server for Yahoo
  --
  strRegExpMailServer = '(http://[^/]+/)([my][mc])/',
  
  -- Redirect site on login
  --
  strRegExpMetarefresh  = 'window.location.replace%("([^"]*)"',

  -- Get the html corresponding only to the message list
  --
  strMsgListHTMLPattern = '<table id="datatable".*<tbody>(.*)</tbody>.*</table>',

  -- Get the crumb value that is needed for deleting messages and emptying the trash
  --
  strRegExpCrumb = '<input.-name="[%.m]crumb" value="([^"]+)">',

  -- Delete Form hidden items
  --
  strHiddenItems = '<input type="hidden" name="([^"]+)".- value="([^"]-)">',
  strDeletePostPat = '<form name=messageList method=post action="/([^"]+)">',

  -- Mark unread url
  -- 
  strMsgMarkUnreadPat = '<a href="/([my][cm][^"]*UNR=1[^"]*)">',

  -- Pattern to determine if we have no messages.  If this is found, we have messages.
  --
  strMsgListNoMsgPat = "(<tbody>)",
  
  -- Pattern to determine if we have no messages with 'mc'.  If found, there is no messages.
  --
  strMsgListNoMsgPatMC = '(modulecontainer filled nomessages)',

  -- Used by Stat to pull out the message ID and the size
  --
  strMsgLineLitPattern = ".*<td>[.*]{div}[.*]{h2}.*<a>.*</a>[.*]{/h2}[.*]{/div}.*</td>.*<td>.*</td>.*<td>.*</td>.*</tr>",
  strMsgLineAbsPattern = "O<O>[O]{O}[O]{O}O<X>O<O>[O]{O}[O]{O}O<O>O<O>O<O>O<O>X<O>O<O>",
    
  -- MSGID Pattern
  -- 
  strMsgIDPattern = 'MsgId=([^&]*)&',
  strMsgIDMCPattern = 'mid=([^&]*)&',

  -- Pattern used by Stat to get the next page in the list of messages
  --
  strMsgListPrevPagePattern = '<a href="/([my][cm][^"]*previous=1[^"]*)">',
  strMsgListNextPagePatternMC = '| <a href="([^"]+)"><span[^|]+| <a href="[^"]+&last=1">',

  -- Pattern for emptying all
  --
  strEmptyAllPat = 'url %+= "=1&([^"]+)"',

  -- Defined Mailbox names - These define the names to use in the URL for the mailboxes
  --
  strInbox = "Inbox",
  strBulk = "@B@Bulk",
  strTrash = "Trash",
  strDraft = "Draft",
  strSent = "Sent",

  -- Folder patterns -- To add standard mailbox names, add the names, separated by a '~'
  --
  strInboxPat = "inbox~InArrivo~inarrivo",
  strBulkPat = "Bulk~bulk~Anti%-spam~antispam",
  strDraftPat = "Bozza~bozza",
  strTrashPat = "Cestino~cestino",
  strSentPat = "Inviati~inviati",

  -- Command URLS
  --
  strCmdMsgList = "%s%s/ShowFolder?box=%s&Npos=%d&Nview=%s&view=%s&order=down&sort=date&reset=1&Norder=up",
  strCmdMsgListMC = "%s%s/showFolder?fid=%s&startMid=%s&ymv=0&&sort=date&order=down&filterBySelect=%s&filterBySelect=%s&prefNumOfMid=500",
  strCmdMsgView = "%sya/download?box=%s&MsgId=%s&bodyPart=%s&download=1&YY=38663&y5beta=yes&y5beta=yes&order=down&sort=date&pos=0&view=a&head=b&DataName=&tnef=&Idx=0",
  strCmdMsgWebView = "%s%s/ShowLetter?box=%s&MsgId=%s",
  strCmdMsgWebViewMC = "%s%s/showMessage?fid=%s&midIndex=0&mid=%s&eps=&f=1&",
  strCmdEmptyTrash = "%s%s/ShowFolder?ET=1&", 
  strCmdEmptyTrashMC = "%s%s/showFolder?Etrash=1&",
  strCmdDeleteMC = "%s%s/showFolder?fid=%s&top_bpress_delete=Delete&top_mark_select=0&top_move_select=&mcrumb=",

  strCmdEmptyBulk = "%s%s/ShowFolder?EB=1&", 
  strCmdEmptyBulkMC = "%s%s/showFolder?Ebulk=1&",
  strCmdUnread = "%s%s/ShowLetter?box=%s&MsgId=%s&.crumb=%s&UNR=1",

  -- Emails to list - These define the filter on the messages to grab
  --
  strViewAll = "a",
  strViewUnread = "u",
  strViewFlagged = "f",

  strViewAllPat = "([Aa]ll)",
  strViewUnreadPat = "([Uu]nread)",
  strViewFlaggedPat = "([Ff]lagged)",

  -- Internation Flags
  --
  strYahooUs = "us",  -- US
  strYahooIt = "it",  -- Italy
  strYahooCa = "ca",  -- Canada
  strYahooDk = "dk",  -- Denmark
  strYahooDe = "de",  -- Germany
  strYahooEs = "es",  -- Spain
  strYahooFr = "fr",  -- France
  strYahooNo = "no",  -- Norway
  strYahooSe = "se",  -- Sweden
  strYahooUk = "uk",  -- United Kingdom
  strYahooIe = "ie",  -- Ireland
  strYahooAu = "au",  -- Australia
  strYahooNz = "nz",  -- New Zealand
  strYahooCn = "cn",  -- China
  strYahooHk = "hk",  -- Hong Kong
  strYahooIn = "in",  -- India
  strYahooId = "id",  -- Indonesia
  strYahooJp = "jp",  -- Japan
  strYahooKr = "kr",  -- Korea
  strYahooSg = "sg",  -- Singapore
  strYahooTw = "tw",  -- Taiwan
  strYahooAr = "ar",  -- Argentina
  strYahooBr = "br",  -- Brazil
  strYahooMx = "mx",  -- Mexico

  -- New Interface Strings
  --

  -- SOAP Urls
  --
  strSoapCmd = "%s%s?m=%s&wssid=%s&appid=YahooMailRC", 
  --strCmdAttach = "%sya/download?fid=%s&mid=%s&pid=2&tnef=&YY=189019855&newid=1&clean=0&inline=1",
  strCmdAttach = "%sya/download?fid=%s&mid=%s&pid=%s&tnef=&clean=0&redirectURL=%sdc/virusresults.html%%3Ffrom%%3Ddownload_response%%26ui%%3Diframe%%26YY%%3D1163030279984",
  
--"%sym/cgdownload/?box=%s&MsgId=%s&bodyPart=%s&download=1",
--"%sya/download?fid=%s&mid=%s&pid=%s&tnef=&clean=0&",                   

  strRedirectNew = 'content="0; url=([^"]+)">',
  strYahooxlms = "ymws",

  -- SOAP Constants
  --
  strGre_Gve = "8",
  strGre_Gid = "cg",

  -- Patterns
  --
  strRegExpMailServerNew = '(http://[^/]+/)dc/',

  -- Data Recognization on login
  --
--  strRegExpCrumbNew = "wssid : '([^']+)'",
  strRegExpCrumbNew = "wssid[^:]+: '([^']+)'",
  strRegExpWebSrvUrl = "webservice[^:]-: '([^']+)'", 

  -- Folder names
  --
  strBulkNew = "%40B%40Bulk",
}

-- ************************************************************************** --
--  State - Declare the internal state of the plugin.  It will be serialized and remembered.
-- ************************************************************************** --

internalState = {
  bStatDone = false,
  bLoginDone = false,
  strUser = nil,
  strPassword = nil,
  browser = nil,
  strMailServer = nil,
  strFileServer = nil,
  strDomain = nil,
  strMBox = nil,
  strIntFlag = nil,
  strView = nil,
  bMarkMsgAsUnread = false,
  bNoSSL = false,
  bEmptyTrash = false,
  bEmptyBulk = false,
  msgids = {},
  strStatCache = nil,
  statLimit = nil,
  classicType = nil,

  -- New Interface pieces
  --
  bNewGUI = false,
  strWebSrvUrl = nil,
  strGSS = nil,

  -- Windows event logging
  logger = nil
}




-- ************************************************************************** --
--  Utility functions
-- ************************************************************************** --

-- copies all elements from src into dest
function copy_from(dest, src)
  for i, v in pairs(src) do
    dest[i] = v
  end
end

-- split str into parts separated by div
function split(str, div)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- chars left of divider
    pos = sp + 1 -- sp points to the last character in the divider
  end
  table.insert(arr,string.sub(str,pos)) -- chars right of divider
  return arr
end

function quote_string(val) return string.format("%q",val) end
function get_nil_string() return "nil" end

function table_to_string(t, depth)
  local result
  if (depth >= 0) then -- and getmetatable(val) == nil then
    local tmp = {}
    table.foreach( t,
      function (k,v)
        table.insert(tmp, tostr(k, depth-1) .. "=" .. repr(v, depth-1))
      end
    )
    result = "{" .. table.concat(tmp,", ") .. "}"
  else
    result = tostring(t)
  end
  return result
end

-- Create a literal string representation of the given object
local repr_map = {
  ["table"] = table_to_string
  ,["string"] = quote_string
  ,["nil"] = get_nil_string
  ,["number"] = tostring
  ,["boolean"] = tostring
  ,["default"] = tostring
}

local repr_max_depth=2
function repr( val, depth )
  local val_type = type(val)
  local func
  depth = depth or repr_max_depth
  func = repr_map[val_type] or repr_map["default"]
  return func(val, depth)
end

-- Convert any object to a string
-- Unlike repr, tostr is idempotent and does not add double quotes to a string.
function tostr( val )
  if type(val) == "string" then
    return val
  end
  return repr(val)
end



-- ************************************************************************** --
--  CRLF string functions
-- ************************************************************************** --

-- Returns "data" with "{LF}" prefixing all \n and "{CR}" prefixing all \r,
--   so hex viewing for those bytes isn't necessary.
--
function showCRLF( data )
  local str = data
  if str then
    str = string.gsub(str, "\n", "{LF}\n")
    str = string.gsub(str, "\r", "{CR}\r")
  end
  return str
end

-- Returns a new string with all single \r and \n replaced by \r\n
function fixCRLF( str )
  if str then
    -- temporarily convert proper ending to \n
    str = string.gsub(str, "\r\n", "\n")
    str = string.gsub(str, "\r", "\n") -- should we worry about embedded \r?
    str = string.gsub(str, "\n", "\r\n")
    
    -- this alternative is actually a bit slower:
--    str = string.gsub(str, "([^\r]-)\n", "%1\r\n")
  end
  return str
end



-- ************************************************************************** --
--  Logging functions
-- ************************************************************************** --

-- We intercept log.dbg, log.err, etc. to add more detailed logging to 
--  the raw log file in addition to the usual log.txt.
-- Raw Logging does not modify the given log line or data in any way:
--   i.e. the strings are not truncated and any CR / LFs are written unchanged.
--   The current date and time is also prefixed.
-- 
-- Example entry:
--   12/05/04 03:48:17 : My Log Line
--   --------------------------------------------------
--   My Data
--   --------------------------------------------------
--

-- Set to true to enable Raw Logging
--
local ENABLE_LOGRAW = _DEBUG

-- The platform dependent End Of Line string
-- e.g. this can be changed to "\n" under UNIX, etc.
-- this is presently just used for the log file.
local EOL = "\r\n"

-- The raw logging functions
--
log = log or {} -- fast hack to make the xml generator happy
log.err = log.error_print
-- logging functions:
log.kinds = { "err", "dbg", "warn", "say" }

-- keep a copy of the original log function table
local log_original = {}

-- modify the log table to reroute calls to do_log
function use_do_log()
  copy_from(log_original, log)
  -- redirect log functions to use do_log
  for i,kind in pairs(log.kinds) do
    log[kind] = function( line, data )
      log_do_log(kind, line, data)
    end
  end
  -- use log.err but also intercept log.error_print
  log.error_print = log.err
end

-- NOTE: the standard log functions will not accept a second data
--  parameter.  e.g. something like log.dbg(line, data) will cause
--  lua to crash with "L: lua stack image...", so we must always
--  install replacements.
use_do_log()

log_raw_write = function( line, data )
  local out = assert(io.open("log_raw.txt", "ab"))
  out:write( EOL .. os.date("%c") .. ": " )
  out:write( tostr(line) )
  if (data ~= nil) and (data ~= "") then
    out:write( EOL .. "--------------------------------------------------" .. EOL )
    out:write( data )
    out:write( EOL .. "--------------------------------------------------" )
  end
  assert(out:close())
end

-- central logging function
log_do_log = function( kind, line, data )
  -- intercepting the logger calls adds stack frames, causing
  --  the currentline in log.txt to be incorrect, so we add
  --  the actual line number as a prefix.
  -- 1=this, 2=caller (generated), 3=caller's caller (source)
  local info = debug.getinfo(3, "l") -- l=currentline, S=info.short_src
  local prefix = ""
  if info then
    prefix = "["..kind.."@"..tostr(info.currentline).."] "
  else
    prefix = "["..kind.."@?] "
  end

--  if data ~= nil then
--    data = tostr(data)
--    if DBG_MAX_LEN and DBG_MAX_LEN >= 0 then
--      data = data:sub(1,DBG_MAX_LEN)
--    end
--  end

  -- write all data to log_raw.txt
  if ENABLE_LOGRAW then
    log_raw_write( prefix .. line, data )
  end

  -- call original logger to write to FreePOPs log.txt
  func = log_original[kind]
  func( prefix .. line )
end

function dbg_limit(str)
  if (str ~= nil) and (type(str) == "string") and DBG_LEN and (DBG_LEN >= 0) then
    str = string.sub(str,1,DBG_LEN)
  end
  return str
end


-- ************************************************************************** --
--  Helper functions
-- ************************************************************************** --

-- Serialize the state
--
-- serial. serialize is not enough powerfull to correcly serialize the 
-- internal state. the problem is the field b. b is an object. this means
-- that is a table (and no problem for this) that has some field that are
-- pointers to functions. this is the problem. there is no easy way for the 
-- serial module to know how to serialize this. so we call b:serialize 
-- method by hand hacking a bit on names
--
function serialize_state()
  internalState.bStatDone = false;
	
  return serial.serialize("internalState", internalState) ..
		internalState.browser:serialize("internalState.browser") ..
		 internalState.logger:serialize("internalState.logger")
end

-- Computes the hash of our state.  Concate the user, domain, mailbox and password
--
function hash()
  return (internalState.strUser or "") .. "~" ..
         (internalState.strDomain or "") .. "~"  ..
         (internalState.strMBox or "") .. "~" ..
         (internalState.strView or "") .. "~" ..
	 internalState.strPassword -- this asserts strPassword ~= nil
end

-- Check to see if the GUI is the new one
--
function checkForNewGUI(browser, body)
  local server = string.match(browser:whathaveweread(), globals.strRegExpMailServerNew)
  if (server ~= nil) then 
    log.dbg("Detected New Version of the Yahoo interface!", browser:whathaveweread())
    log.dbg("Yahoo Mail Server: " .. server)

    internalState.strMailServer = server
    internalState.bNewGUI = true
    return true
  end

  return false
end

-- Issue the command to login to Yahoo
--
function loginYahoo()
  -- Check to see if we've already logged in
  --

  log.dbg( "Entering loginYahoo()" )

  if internalState.loginDone then
    log.dbg( "internalState.loginDone" )
    return POPSERVER_ERR_OK
  end

  -- Create a browser to do the dirty work (It must be set to IE 6.0)
  --
  internalState.browser = browser.new("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; {02ABE9F9-C33D-95EA-0C84-0B70CD0AC3F8}; .NET CLR 1.1.4322)")
--  internalState.browser = browser.new("Mozilla/4.0 (compatible; U; en)")
--  internalState.browser = browser.new("Mozilla/3.0 (U; en)")
--  internalState.browser = browser.new("FreePOPs/2.5 (U; en)")
  local SSLEnabled = browser.ssl_enabled()
  
  -- Create the windows event logger
  internalState.logger = wel.new('FreePOPs','yahoo')

  -- Define some local variables
  --
  local username = internalState.strUser
  local password = internalState.strPassword
  local domain = internalState.strDomain
  local intFlag = internalState.strIntFlag
  local url = globals.strLoginHTTP
  local browser = internalState.browser
  local post
  local challengeCode, uVal

  -- Handle rocketmail
  --
  if (domain == "rocketmail.com") then
    domain = "yahoo.com"
    username = username .. ".rm"
  elseif (domain == "btinternet.com" or domain == "talk21.com") then
    username = username .. "@" .. domain
  end
	
  -- DEBUG - Set the browser in verbose mode
  --
  -- browser:verbose_mode()

  if internalState.bNoSSL == true then
    log.dbg("Yahoo: SSL login will not be used.")
    SSLEnabled = false
  end

  if SSLEnabled then
    url = globals.strLoginHTTPs
    browser:ssl_init_stuff()
  end

  -- Login to Yahoo
  --
  log.dbg( "login get: " .. globals.strLoginPage )
  local body, err = browser:get_uri(globals.strLoginPage)
  log.dbg( "login response: err=" .. tostr(err), dbg_limit(body) )
  
  if body ~= nil then
    challengeCode = string.match(body, globals.strLoginChallenge)
    uVal = string.match(body, globals.strLoginU)
  end

  if (uVal == nil) then
    uVal = ""
  end

  if challengeCode ~= nil then
    password = crypto.bin2hex(crypto.md5(password))
    password = crypto.bin2hex(crypto.md5(password .. challengeCode))
    post = string.format(globals.strLoginPostDataMD5, intFlag, username,
                         password, challengeCode, uVal)
  else -- if we didn't get the challenge code, then login in cleartext
    post = string.format(globals.strLoginPostData, intFlag, username, password, uVal)
  end

  log.dbg( "login challenge post: \nurl=" .. url .. " \npost=" .. post )
  body, err = browser:post_uri(url, post)
  log.dbg( "login challenge response: err=" .. tostr(err), dbg_limit(body) )

  -- Check for redirect
  --
  local str = string.match(body, globals.strRedirectNew)
  if (str ~= nil) then
    log.dbg( "login redirect get: " .. str )
    body, err = browser:get_uri(str)
    log.dbg( "login redirect response: err=" .. tostr(err), dbg_limit(body) )
  end

  -- Check for NewGUI and Try Beta
  local bNewGui = false
  local url = browser:whathaveweread()
  log.dbg("browser:whathaveweread()=" .. url)
  str = string.match(url, '/dc/try_mail')
  if (str == nil) then
    -- it's not a "try" page.  Check if its the new gui.
    bNewGui = checkForNewGUI(browser, body)
    if (bNewGui == true) then
      return loginNewYahoo(browser, body) 
    end
  else
    -- it is a try page, so reply, no thanks
    post = "newStatus=1"
    log.dbg( "try beta post: \nurl=" .. url .. " \npost=" .. post )
    body, err = browser:post_uri(url, post)
    log.dbg( "try beta response: err=" .. tostr(err), dbg_limit(body) )
  end

  -- Do some error checking
  --
  if (body == nil) then
    -- No connection
    --
    log.err( "Login Failed: Unable to make connection (body == nil)" )
    return POPSERVER_ERR_NETWORK
  end

  local str = string.match(body, '<input type="text" id="secword" name=".secword"')
  if (str ~= nil) then
    log.err("Login Failed: Yahoo is using an image verification.  Please login through the web.")
    return POPSERVER_ERR_NETWORK
  end

  -- Check for invalid password
  -- 
  local str = string.match(body, globals.strRetLoginBadPassword)
  if str ~= nil then
    log.err("Returned Page saying invalid password: ", body)
    internalState.logger:error("user: " .. username .. "\nerror: bad password")
    return POPSERVER_ERR_AUTH
  end

  -- Extract the mail server
  --
  local lastUrl = browser:whathaveweread()
  local str, version = string.match(lastUrl, globals.strRegExpMailServer)
  if str == nil or version == nil then
    log.err("Login Failed: Unable to find mail server url in body.")
    return POPSERVER_ERR_UNKNOWN
  else
    internalState.strMailServer = str
	internalState.classicType = version
    log.dbg("internalState.strMailServer = " .. str)
  end

  -- If we are using HTTPS, we need to look for the meta-refresh link
  -- returned by the login response and go to it.
  if (challengeCode ~= nil) then
    str = string.match(body, globals.strRegExpMetarefresh)
    if (str ~= nil) then
      log.dbg("HTTPS meta-refresh get: " .. str)
      body, err = browser:get_uri(str)
      log.dbg("HTTPS meta-refresh response: err=" .. tostr(err), dbg_limit(body))
      
      -- Here's the other check (SSL) for the beta interface
      --
      bNewGui = checkForNewGUI(browser, body)
      if (bNewGui == true) then
        return loginNewYahoo(browser, body) 
      end
    end
  end
  
  if (internalState.classicType == "mc") then
    str = string.match(body, 'var classicHost = "([^"]+)";')
	if (str ~= nil) then
	  internalState.strFileServer = str
	else 
      internalState.strFileServer = string.gsub(internalState.strMailServer, "mc", "f")
	end
    log.dbg("Yahoo download Server: " .. internalState.strFileServer)
  end
    
  -- DEBUG Message
  --
  log.dbg("Yahoo Mail Server: " .. internalState.strMailServer)

  -- Note that we have logged in successfully
  --
  internalState.bLoginDone = true
	
  -- Debug info
  --
  log.dbg("Created session for " .. 
    internalState.strUser .. "@" .. internalState.strDomain)

  -- Return Success
  --
  return POPSERVER_ERR_OK
end

-- Login into the new yahoo
--
function loginNewYahoo(browser, body) 
  -- Let's get the crumb value
  --
  local str = string.match(body, globals.strRegExpCrumbNew)
  if str == nil then
    log.err("Yahoo - unable to parse out crumb value.  Deletion will fail, Body: ", tostr(body))
    return POPSERVER_ERR_UNKNOWN
  end
  log.dbg("Crumb Value: " .. str)
  internalState.strCrumb = str

  -- Get the Web Service Url
  --
--  local str = string.match(body, globals.strRegExpWebSrvUrl)
--  if str == nil then
--    log.dbg("Yahoo - unable to parse out web service Url.  Body: " .. 
--      tostr(body))
--    return POPSERVER_ERR_UNKNOWN
--    str = "ws/mail/v1/soap"
--  end
  -- We used to query for this.
  --
  internalState.strWebSrvUrl = "ws/mail/v1/soap"

  -- Get metadata
  --
  if (getUserMetaData() == 1 or getUserData() == 1 or getFolderList() == 1) then
    return POPSERVER_ERR_UNKNOWN
  end

  -- Note that we have logged in successfully
  --
  internalState.bLoginDone = true
	
  -- Debug info
  --
  log.dbg("Created session for " .. 
    internalState.strUser .. "@" .. internalState.strDomain)

  -- Return Success
  --
  return POPSERVER_ERR_OK
end


-- converts the given regex str to a case insensitive version
function case_insensitive_regex(str)
  local re = str:gsub("%a",
    function (c)
      return "["..c:upper()..c:lower().."]"
    end )
  return re
end

-- case insensitive regular expressions
local re_ctype_boundary = case_insensitive_regex('\nContent%-Type: multipart.-boundary="+(.-)"+[\r\n]')
local re_cdisp = case_insensitive_regex('(Content%-Disposition')..':%s.-)\r\n'
local re_ctype = case_insensitive_regex('(Content%-Type')..':%s.-)\r\n'

function yahoo_classic_get_header(browser, hdrUrl)
  local headers, http_head, http_body, err
  local bFail = true

  log.dbg("hdrUrl = " .. hdrUrl)

  for i=1,3 do
    log.dbg("Getting header... attempt # "..tostr(i))
--    headers, err = browser:get_uri(hdrUrl)
    http_head, http_body, err = browser:get_head_and_body(hdrUrl)
    log.dbg("get_header i="..tostr(i)..", http_head=", tostr(http_head))
    headers = http_body
  
    if headers then
      -- Remove the SMTP envelope From_ line (Yahoo's mbox format) if it's first
      if (string.sub(headers,1,5) == "From ") then
        headers = string.gsub(headers, "From .-\n", "", 1);
      end
    
      -- sanity check: verify the first field of the header has the proper format:
      --  Field-Name: Field-Value
      --    Field-Value-Continued
      local s, e, field_name, field_value
      s, e, field_name, field_value = headers:find("^([%w%-_]+):[ ]*(.-)\n%w", 1)
      -- require:
      -- 1. first line in mail header is a valid field, and
      -- 2. Content-Disposition in http_head
      -- could also check redirect url
      if (s == nil) or (string.match(http_head, re_cdisp) == nil) then
        log.err("*** INVALID e-mail header! i="..tostr(i)..", err="..tostr(err)..", headers=", headers)
      else
        log.dbg("Header # "..tostr(i).." passed basic check.  First field = "..tostr(field_name))
        bFail = false
        break
      end
    else
      log.err("*** RECEIVED A NIL HEADER?  BAD URL? i="..tostr(i))
    end
    
  end
  
  if bFail then
    log.err("*** ERROR!!! COULD NOT DOWNLOAD A VALID HEADER!, last header=", tostr(headers))
    return "ERROR"
  end
  
  return http_head, headers, err
end

function yahoo_classic_mc_get_header(browser, hdrUrl) 
  local http_head, headers, err = yahoo_classic_get_header(browser, hdrUrl)
  
  if (headers ~= nil) then
	headers = string.gsub(headers, "\n", "~~~")
	headers = string.gsub(headers, "~~~", "\r\n")
  end
  
  return http_head, headers, err
end

function yahoo_classic_get_body(browser, bodyUrl)
  local http_head, http_body, err
  local bFail = true

  log.dbg("bodyUrl = " .. bodyUrl)

  for i=1,3 do
    log.dbg("Getting body... attempt # "..tostr(i))
    http_head, http_body, err = browser:get_head_and_body(bodyUrl)
    log.dbg("get_body i="..tostr(i)..", err="..tostr(err)..", http_head=", tostr(http_head))

    -- http_head should not be empty, but the browser is broken.
    -- 404: asked for a bad Url (at the end of the body parts)
    if (http_head == nil) and (
      (not http_body) or
      (http_body:match('^404: Not Found'))
      )
    then
      bFail = false
      break
    end

    -- check for bad body
    -- Content-Disposition http field is required for a valid body
    -- could also check redirect url
    if err or (http_head == nil) or (string.match(http_head, re_cdisp) == nil)
--      http_body:match('^The document has moved <A HREF="https://login.yahoo.com/config/login_verify') or
--      http_body:match('^SSL certificate problem, verify that the CA cert is OK') or
--      (
--        -- commented out because it may change more often.
----      http_body:match('^\n\n\n\n\n\n\n  \n<!DOCTYPE HTML PUBLIC') and
--      http_body:match('<title>Sign in to Yahoo!</title>') and
--      http_body:match('<h1>Please verify your password</h1>')
--      )
    then
      log.err("*** INVALID e-mail body! i="..tostr(i)..", err="..tostr(err)..", http_head=", http_head)
      log.dbg("*** INVALID e-mail body! http_body=", http_body)
    else
--      log.dbg("Body passed basic check. i="..tostr(i))
      log.dbg("Body passed basic check. i="..tostr(i)..", err="..tostr(err)..", http_head=", http_head)
      log.dbg("Body passed basic check.  http_body=", http_body)
      bFail = false
      break
    end
  end
  
  if bFail then
    log.err("*** ERROR!!! COULD NOT DOWNLOAD A VALID BODY!, last body=", tostr(http_body))
    return "ERROR"
  end
  
  return http_head, http_body, err
end


-- Download a single message
--
function downloadYahooMsg(pstate, msg, nLines, data)
  -- Make sure we aren't jumping the gun
  --
  
  log.dbg("Entering downloadYahooMsg")
  
  local retCode = stat(pstate)
  if retCode ~= POPSERVER_ERR_OK then 
    return retCode 
  end

  -- Local Variables
  --
  local browser = internalState.browser
  local uidl = get_mailmessage_uidl(pstate, msg)
  local size = get_mailmessage_size(pstate, msg)
  local msgid = nil
  local hdrUrl = nil
  local bodyUrl = nil
  local result, err, http_head, http_body, headers

  -- Get the header
  --
  if internalState.bNewGUI then
    local msgid = internalState.msgids[uidl]
    uidl = msgid
    headers = getMsgHdr(pstate, uidl)
  elseif (internalState.classicType == 'mc') then
    msgid = internalState.msgids[uidl]
	hdrUrl = string.format(globals.strCmdAttach, internalState.strFileServer,
		internalState.strMBox, msgid, "HEADER", internalState.strMailServer)

    http_head, headers, err = yahoo_classic_mc_get_header(browser, hdrUrl)	
  else
    msgid = internalState.msgids[uidl]
    hdrUrl = string.format(globals.strCmdMsgView, internalState.strMailServer, 
	  internalState.strMBox, msgid, "HEADER");

--      local escUidl = string.gsub(msgid, "%+", "%%2B")
--      hdrUrl = string.format(globals.strCmdMsgView,
--        internalState.strMailServer,
--        internalState.strMBox,
--        escUidl, "HEADER", internalState.strMailServer)

    http_head, headers, err = yahoo_classic_get_header(browser,hdrUrl)
   
    if http_head == "ERROR" then
      return POPSERVER_ERR_UNKNOWN
    end
  end

  -- Define a structure to pass between the callback calls
  --
  local cbInfo = {
    -- Headers - not used for anything
    --
    strHeaders = headers,

    -- Whether this is the first call of the callback
    --
    bFirstBlock = true,

    -- String hacker
    --
    strHack = stringhack.new(),

    -- String buffer
    --
    strBuffer = "",

    -- Lines requested (-2 means no limited)
    --
    nLinesRequested = nLines,

    -- Lines Received - Not really used for anything
    --
    nLinesReceived = 0,

    -- attachments table
    --
    attachments = {},
    inlineids = {}, 

    -- Text
    --
    strHtml = nil,
    strText = nil,
  }

  -- Define the callback
  --
  local cb = downloadMsg_cb(cbInfo, data)

  -- Remove the SMTP envelope From_ line (Yahoo's mbox format) if it's first
  --
  if string.sub(headers,1,5) == "From " then
    headers = string.gsub(headers, "From .-\n", "", 1);
  end

  -- Remove "Content-Transfer-Encoding" line from the header.
  --
  -- Yahoo apparently converts the received encoding to some other
  -- encoding (7bit, 8bit, or binary?) without updating the headers.
  -- (quoted-printable and base64 values are incorrect)
  --
  -- Case-insensitive
  --
  headers = string.gsub(headers, "[Cc][Oo][Nn][Tt][Ee][Nn][Tt]%-[Tt][Rr][Aa][Nn][Ss][Ff][Ee][Rr]%-[Ee][Nn][Cc][Oo][Dd][Ii][Nn][Gg]: .-\n", "");
  --headers = string.gsub(headers, "Content%-Transfer%-Encoding: quoted%-printable%s+", "");
  --headers = string.gsub(headers, "charset=%"UTF%-8%", "charset=%"us%-ascii%"");

  -- Send headers and start download on the body
  -- 
  if (internalState.bNewGUI) then
    headers = string.gsub(headers, "\n", "\r\n")
    headers = string.gsub(headers, "\r\n$", "")

    headers = mimer.remove_lines_in_proper_mail_header(headers, {"content%-type",
		"content%-disposition", "mime%-version", "boundary"})

    if nLines == 0 then
      cbInfo.strText = ""
    else
      getMsgBody(pstate, uidl, size, cbInfo)
    end
    mimer.pipe_msg(
      headers, 
      cbInfo.strText, 
      cbInfo.strHtml, 
      internalState.strMailServer, 
      cbInfo.attachments, browser, 
      function(s)
--        if s then log.dbg("sending s=",s) end
        popserver_callback(s,data)
      end, cbInfo.inlineids)
  else -- Yahoo Classic
    -- send the headers directly
    popserver_callback(headers,data)
    log.dbg("sent headers = ", headers)

    -- if multipart, then get all the parts
    local boundary = headers:match(re_ctype_boundary)
    log.dbg("boundary="..tostr(boundary))
    if boundary then
      local send_base64 = mimer.base64_io_slave( cb )
      log.dbg("Processing a multipart!")

      -- until we put in more error checks,
      -- set to a maximum of 10 sub-parts.
      for i=1,10 do
        local bSendBodyBase64 = false

		if (internalState.classicType ~= 'mc') then
          bodyUrl = string.format(globals.strCmdMsgView, internalState.strMailServer,
            internalState.strMBox, msgid, tostr(i))
		else  
		  bodyUrl = string.format(globals.strCmdAttach, internalState.strFileServer,
		    internalState.strMBox, msgid, i, internalState.strMailServer)
		end

--        local escUidl = string.gsub(msgid, "%+", "%%2B")
--        bodyUrl = string.format(globals.strCmdMsgView,
--          internalState.strMailServer,
--          internalState.strMBox,
--          escUidl, tostr(i), internalState.strMailServer)

        http_head, http_body, err = yahoo_classic_get_body(browser, bodyUrl)

        if http_head == "ERROR" then
          return POPSERVER_ERR_UNKNOWN
        end
        
--        http_head, http_body, err = browser:get_head_and_body(bodyUrl)
--        log.dbg("browser:get_uri: err="..tostr(err))
--        log.dbg("http_head = ", http_head)
--        log.dbg("http_body = ", http_body)

        if http_head == nil then
          log.dbg("Finished all "..tostr(i-1).." parts.")
          break
        end

        local cdisp = nil
        local ctype = http_head:match(re_ctype)
        log.dbg("ctype = "..tostr(ctype))
        local ctenc = nil

        if ctype == nil then
          log.dbg("ERROR: could not find Content-Type field!")
          break
        end
        
        if ctype:match('multipart/') then
          local boundary_inner = http_body:match('%s*%-%-(.-)[\r\n]')
          log.dbg("boundary_inner="..tostr(boundary_inner))
          if boundary_inner == nil then
            log.dbg("ERROR: multipart, but no boundary separator found!")
            break
          end
          ctype = ctype .. string.format(';\r\n boundary="%s"\r\n', boundary_inner)
          log.dbg("fixed ctype = "..tostr(ctype))
        elseif
          ctype:match('application/') or 
          ctype:match('image/') or
          ctype:match('video/') or
          ctype:match('audio/') then

          ctenc = "Content-Transfer-Encoding: base64"
          bSendBodyBase64 = true

          cdisp = http_head:match(re_cdisp)
          log.dbg("cdisp = "..tostr(cdisp))
          cdisp = string.gsub(cdisp, "%%(%x%x)",
            function(h) return string.char(tonumber(h,16)) end
          )
          log.dbg("fixed cdisp = "..tostr(cdisp))

        end

        local t = {}
        table.insert(t, ctype)
        table.insert(t, ctenc)
        table.insert(t, cdisp)
        table.insert(t, "\r\n") -- end with 2 CRLFs, just to be safe

        cb("\r\n--"..boundary.."\r\n")

        cb(table.concat(t,"\r\n"))

        if bSendBodyBase64 then
          send_base64(http_body, #http_body)
          send_base64("",0)
        else
          cb(http_body, #http_body)
        end
        
      end -- for

      cb("\r\n--"..boundary.."--".."\r\n\r\n")
      
      result = true
      
    else -- just one part
      log.dbg("Only one part.  downloading...")
		
	  if (internalState.classicType ~= 'mc') then
        bodyUrl = string.format(globals.strCmdMsgView, internalState.strMailServer,
          internalState.strMBox, msgid, "TEXT")
	  else  
	    bodyUrl = string.format(globals.strCmdAttach, internalState.strFileServer,
		  internalState.strMBox, msgid, "TEXT", internalState.strMailServer)
	  end
		
      http_head, http_body, err = yahoo_classic_get_body(browser, bodyUrl)
      cb(http_body, #http_body)
--      result, err = browser:pipe_uri(bodyUrl,cb)

      result = http_body
    end

    if not result then
      log.dbg("Empty message. err="..tostr(err))
    else
      -- Just send an extra carriage return
      log.dbg("Message Body has been processed.")
      if (cbInfo.strBuffer ~= "\r\n") then
        log.dbg("Message doesn't end in CRLF, adding to prevent client timeout.")
        popserver_callback("\r\n\0", data)
      end
    end

  end

  -- Do we need to mark the message as unread?
  --
  if internalState.bNewGUI and internalState.bMarkMsgAsUnread == true then
    log.dbg("Marking as message: " .. uidl .. " as unread");
    markMsgUnread(uidl)
  elseif internalState.bNewGUI == false and internalState.classicType ~= 'mc' then
    local cmdUrl = string.format(globals.strCmdMsgWebView, internalState.strMailServer,
      internalState.classicType, internalState.strMBox, msgid);
    if (internalState.bMarkMsgAsUnread) then
      local str, _ = browser:get_uri(cmdUrl) 
      str = string.match(str, globals.strMsgMarkUnreadPat)
      if str == nil then
        log.warn("Unable to get the url for marking message as unread.")
      else
        cmdUrl = internalState.strMailServer .. str;
        log.dbg("Marking message: " .. msgid .. " as unread, url: " .. cmdUrl);
        browser:get_uri(cmdUrl) -- We don't care about the results.
      end
    else
      -- Mark the message as read
      --
      local str, _ = browser:get_head(cmdUrl) 
    end
  elseif internalState.bNewGUI == false and internalState.classicType == 'mc' then
    if (internalState.bMarkMsgAsUnread == false) then
      -- Mark the message as read
      --
      local cmdUrl = string.format(globals.strCmdMsgWebViewMC, internalState.strMailServer, 
	    internalState.classicType, internalState.strMBox, msgid)
      local str, _ = browser:get_uri(cmdUrl) 
    end
  end

  log.dbg("Exiting downloadYahooMsg")

  return POPSERVER_ERR_OK
end

-- Callback for the retr function
--
function downloadMsg_cb(cbInfo, data)
	
  return function(body, len)

    log.dbg("Entering downloadMsg_cb generated function")

    log.dbg("cbInfo.nLinesRequested = " .. cbInfo.nLinesRequested)
    log.dbg("cbInfo.nLinesReceived = " .. cbInfo.nLinesReceived)
    log.dbg("cbInfo.strHack:current_lines() = " .. cbInfo.strHack:current_lines())

--    log.dbg("received text = ", body)

    -- Are we done with Top and should just ignore the chunks
    --
    if (cbInfo.nLinesRequested ~= -2 and cbInfo.nLinesReceived == -1) then
      log.dbg("downloadMsg_cb: return 0, nil")
      return 0, nil
    end

    -- 3/4/2008 - dothack cannot handle embedded NULLs (0x0)
    --  nor can later code somewhere in freepops which causes a timeout,
    --  (probably due to it seeing 0x0 as end-of-string and
    --  truncating the rest, then waiting for more data),
    --  so we remove embedded NULLs (0x0) == %z
    body = string.gsub(body, "%z", "")

    -- Clean up the end of line
    --
    body = fixCRLF(body)
    cbInfo.strBuffer = string.sub(body, -2, -1)

    -- Perform our "TOP" actions
    --
    if (cbInfo.nLinesRequested ~= -2) then
      body = cbInfo.strHack:tophack(body, cbInfo.nLinesRequested)

      -- Check to see if we are done and if so, update things
      --
      if cbInfo.strHack:check_stop(cbInfo.nLinesRequested) then
        cbInfo.nLinesReceived = -1;
        if (string.sub(body, -2, -1) ~= "\r\n") then
          log.err("Does NOT end in CRLF, adding it!")
          body = body .. "\r\n"
        end
      else
        cbInfo.nLinesReceived = cbInfo.nLinesRequested - 
          cbInfo.strHack:current_lines()
      end
    end

    -- End the strings properly
    --
    body = cbInfo.strHack:dothack(body) .. "\0"

    log.dbg("finished text = ", body)

    -- Send the data up the stream
    --
    popserver_callback(body, data)
			
    log.dbg("Exiting downloadMsg_cb generated function")
    
    return len, nil
  end
end

function getMsgCallBack(cbInfo, body)
  -- Do some cleanup
  --
  body = string.gsub(body, "\r\n", "\n")
  body = string.gsub(body, "\n", "\r\n")
   
  -- Perform our "TOP" actions
  --
  if (cbInfo.nLinesRequested ~= -2) then
    body = cbInfo.strHack:tophack(body, cbInfo.nLinesRequested)

    -- Check to see if we are done and if so, update things
    --
    if cbInfo.strHack:check_stop(cbInfo.nLinesRequested) then
      if (string.sub(body, -2, -1) ~= "\r\n") then
        body = body .. "\r\n"
      end
    end
  end

  return body
end

-- ************************************************************************** --
--  SOAP functions
-- ************************************************************************** --

function getUserMetaData()
  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "GetMetaData", internalState.strCrumb)

  local ns, meth, ent, err = soap.http.call(browser,
    url, "urn:yahoo:" .. globals.strYahooxlms, "GetMetaData", 
      {
        {
          tag = "param1", ""
        },
      })

  -- The response means nothing right now
  --
  return 0
end

function getUserData()
  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "GetUserData", internalState.strCrumb)

--  local ns, meth, ent, err = soap.http.call(browser,
--    url, "urn:yahoo:" .. globals.strYahooxlms, "GetUserData", 
--      {
--        {
--          tag = "param1",
--            { tag = "greq", 
--              attr = { ["gve"] = globals.strGre_Gve },
--                { tag = "gid", globals.strGre_Gid }
--            }
--        },
--      })

  -- Need to grab the gres, gss element
  --
--  local str = nil
--  for i, elem in ipairs (ent[2]) do
--    if (elem["tag"] == "gss") then
--      str = elem[1]
--    end
--  end

--  if (str == nil) then
--    log.err("Unable to parse out the gss value.")
--    return 1
--  end
--  internalState.strGSS = str

  return 0
end

function getFolderList()
  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "ListFolders", internalState.strCrumb)

  local ns, meth, ent, err = soap.http.call(browser,
    url, "urn:yahoo:" .. globals.strYahooxlms, "ListFolders", 
      {
        {
          tag = "param1",
            { tag = "resetunseen", "true" } 
        },
      })

  return 0
end

function getSTATList(pstate)
  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "ListMessages", internalState.strCrumb)
  local nMaxMsgs = 999 
  if internalState.statLimit ~= nil then
    nMaxMsgs = internalState.statLimit
  end

  local body = {   
        { tag = "sortKey", "date" }, 
        { tag = "sortOrder", "down" }, 
        { tag = "filterBy", "" }, 
        { tag = "fid", internalState.strMBox }, 
        { tag = "transform-markup", "remove-javascript" },
      }
  body.attr = { 
        ["startMid"] = "0",
        ["numMid"] = nMaxMsgs,
        ["startInfo"] = "0",
        ["numInfo"] = nMaxMsgs,
        ["numBody"] = "0",
  }

  local ns, meth, ent, err = soap.http.call(browser,
    url, "urn:yahoo:" .. globals.strYahooxlms, "ListMessages", body)

  -- Initialize our state
  --
  local nMsgs = 0
  local nTotMsgs = 0
  set_popstate_nummesg(pstate, nMsgs)

  -- Parse the message id's and sizes
  --
  if (ent == nil) then
    internalState.bStatDone = true
    return POPSERVER_ERR_OK
  end

  local knownIDs = {}
  for i, elem in ipairs (ent) do
    if (type(elem) == "table" and elem["tag"] == "messageInfo") then
      local attrs = elem["attr"]
      local size = attrs["size"]     
      local msgid = attrs["mid"]

      local uidl = string.gsub(msgid, "_%d+_", "_000_")

      local bUnique = true
      for j = 0, nMsgs do
        if knownIDs[j + 1] == msgid then
          bUnique = false
          break
        end        
      end

      -- Save the information
      --
      if (bUnique) then
        nMsgs = nMsgs + 1
        log.dbg("Processed STAT - Msg: " .. nMsgs .. ", UIDL: " .. uidl .. ", Size: " .. size)
        set_popstate_nummesg(pstate, nMsgs)
        set_mailmessage_size(pstate, nMsgs, size)
        set_mailmessage_uidl(pstate, nMsgs, uidl)
        knownIDs[nMsgs] = msgid
        internalState.msgids[uidl] = msgid
      end
    end
  end
		
  internalState.bStatDone = true
  return POPSERVER_ERR_OK
end

function getMsgHdr(pstate, uidl)
  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "GetMessageRawHeader", internalState.strCrumb)

  local body = {   
        { tag = "mid", uidl }, 
        { tag = "fid", internalState.strMBox }, 
      }

  local ns, meth, ent, err = soap.http.call(browser,
    url, "urn:yahoo:" .. globals.strYahooxlms, "GetMessageRawHeader", body)

  -- Get the header
  --
  local header = nil
  for i, elem in ipairs (ent) do
    if (type(elem) == "table" and elem["tag"] == "rawheaders") then
      header = elem[1]
      header = header .. "\n"
    end
  end

  -- Make sure we have a valid header
  --
  if (header == nil) then 
    log.err("Invalid header!")
    return nil
  end

  return header
end

function getMsgBody(pstate, uidl, size, cbInfo)
  log.dbg("YahooNew getMsgBody - Entering")

  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "GetMessage", internalState.strCrumb)

  local body = {   
        { tag = "mid", uidl }, 
        { tag = "fid", internalState.strMBox }, 
        { tag = "truncateAt", "999999" }, 
      }

  local ns, meth, ent, err = soap.http.call(browser,
    url, "urn:yahoo:" .. globals.strYahooxlms, "GetMessage", body)

  -- Get the parts
  --
  
--  log.dbg("YahooNew getMsgBody ent[3]=",tostr(ent[3]))

  for i, elem in ipairs (ent[3]) do
    if (type(elem) == "table" and elem["tag"] == "part") then
      local attrs = elem["attr"]
      local partId = attrs["partId"]
      local type = attrs["type"]
      local subtype = attrs["subtype"]
      local textElem = elem[1]
      
      local idPlain = nil
      local idHtml = nil

--      log.dbg("YahooNew getMsgBody partId="..tostr(partId)..
--        ", type="..tostr(type)..", subtype="..tostr(subtype)..
--        ", textElem="..tostr(textElem)..
--        ", attrs=",tostr(attrs))

      -- The main body plain-text and html are handled by the first
      --  two tests and should not be included in attachments.
      -- multipart/alternative results in two parts: text (1), html (2)
      -- if there are more parts (e.g. attachments), the multi/alt body
      --  is usually within the first part, so: text (1.1) and html (1.2)
      -- Don't assume any other plain or html is part of the main body

      if (cbInfo.strText == nil) and
          textElem and textElem["tag"] == "text" and
          (subtype == "plain" or
            (type == "text" and subtype == "")) then
        idPlain = partId
        log.dbg("YahooNew getMsgBody: adding plain text body = "..tostr(idPlain))
        local text = textElem[1]
        if (text == nil) then
          text = ""
        end
        text = text .. "\n"
        cbInfo.strText = getMsgCallBack(cbInfo, text)
        -- remove part from attachments
        cbInfo.attachments[idPlain] = nil

      elseif (cbInfo.strHtml == nil) and
        textElem and textElem["tag"] == "text" and
          subtype == "html" then
        idHtml = partId
        log.dbg("YahooNew getMsgBody: adding html body = "..tostr(idHtml))
        local text = textElem[1]
        text = string.gsub(text, "&amp;", "&")
--        text = string.gsub(text, "(</[^>]+>) ", "%1\r\n") 
        text = text .. "\n"
        cbInfo.strHtml = getMsgCallBack(cbInfo, text)
        -- remove part from attachments
        cbInfo.attachments[idHtml] = nil

      elseif (partId == "HEADER" or partId == "TEXT") then
        log.dbg("YahooNew getMsgBody: partId ignored: "..tostr(partId))
        -- no-op

      else
        -- Only add to attachments once, by partId
        -- We only want the leaves, not the multipart groupings
        if (type ~= "multipart") and
          (partId ~= idPlain) and (partId ~= idHtml) then
          log.dbg("YahooNew getMsgBody: adding an attachment = "..tostr(partId))
          local file = attrs["dispParams"]
          local contentId = attrs["contentId"]
          if (file ~= nil) then
            file = string.gsub(file, "^.-=", "")
            local escUidl = string.gsub(uidl, "%+", "%%2B")
            url = string.format(globals.strCmdAttach, internalState.strMailServer,
               internalState.strMBox, escUidl, partId, internalState.strMailServer)
            cbInfo.attachments[partId] = getRealAttachmentUrl(url)
            -- an empty contentId is not a valid contentId
            if ((contentId ~= nil) and (contentId ~= "")) then
              contentId = string.sub(contentId, 2, -2)
              cbInfo.inlineids[partId] = contentId
            end
          else
            log.dbg("YahooNew getMsgBody: nil dispParams -- attachment NOT ADDED.")
          end
        end
      end
    end
  end
  
--  log.dbg("cbInfo=",tostr(cbInfo))
  
  if not (cbInfo.strText or cbInfo.strHtml) then
    log.dbg("Something isn't right as we got no body back from Yahoo.")
    cbInfo.strText = ""
  end
  
  return 0
end

function markMsgUnread(uidl)
  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "FlagMessages", internalState.strCrumb)

  local ns, meth, ent, err = soap.http.call(browser,
    url, "urn:yahoo:" .. globals.strYahooxlms, "FlagMessages", 
      {
        { tag = "param1",
            { tag = "mid", uidl }, 
            { tag = "fid", internalState.strMBox }, 
            { tag = "setFlags",
                attr = { ["read"] = "0" }, 
                ""
            },
          }, 
      })
end

function emptyFolder(folderName)
  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "EmptyFolder", internalState.strCrumb)

  local ns, meth, ent, err = soap.http.call(browser,
    url, "urn:yahoo:" .. globals.strYahooxlms, "EmptyFolder", 
      {
            { tag = "fid", folderName }, 
      })

  return 0
end

function deleteMsgs(pstate)
  local browser = internalState.browser
  local url = string.format(globals.strSoapCmd, internalState.strMailServer, 
    internalState.strWebSrvUrl, "MoveMessages", internalState.strCrumb)

  local param = { }
  table.insert(param, { tag = "sourceFid", internalState.strMBox })
  table.insert(param, { tag = "destinationFid", globals.strTrash })

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  local cnt = get_popstate_nummesg(pstate)
  local dcnt = 0

  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      local uidl = get_mailmessage_uidl(pstate, i)
      local msgid = internalState.msgids[uidl]
      table.insert(param, { tag = "mid", msgid })
      dcnt = dcnt + 1
    end
  end
  if dcnt == 0 then
    return 0
  end

  local ns, meth, ent, err = soap.http.call(browser,
    url, "urn:yahoo:" .. globals.strYahooxlms, "MoveMessages", 
      param)

  return 0
end

-- Utility Function
--
function getRealAttachmentUrl(url)
  local browser = internalState.browser
  -- get_head redirects, so location will always be nil.
  -- so use get_head_raw which does not redirect:
  local h, err = browser:get_head_raw(url, {}, true)
--  log.dbg("getRealAttachmentUrl: url="..tostr(url))
--  log.dbg("getRealAttachmentUrl: err="..tostr(err)..", h=", h)
  if (err ~= nil) then
    log.dbg(err)
    return nil
  end
  local x = string.match(h,
                "[Ll][Oo][Cc][Aa][Tt][Ii][Oo][Nn]%s*:%s*([^\r]*)")
--  log.dbg("getRealAttachmentUrl: location match: "..tostr(x))
  -- DEBUG:
--  if x then
--    local http_head, http_body, err = browser:get_head_and_body(x)
--    log.dbg("browser:get_get_head_and_body: err="..tostr(err)..", http_head=",
--      tostr(http_head))
--    log.dbg("http_body = ", http_body)
--  end
  return (x or nil)
end


-- ************************************************************************** --
--  Pop3 functions that must be defined
-- ************************************************************************** --

-- Extract the user, domain and mailbox from the username
--
function user(pstate, username)
	
  -- Get the user, domain, and mailbox
  --
  local domain = freepops.get_domain(username)
  local user = freepops.get_name(username)

  internalState.strDomain = domain
  internalState.strUser = user

  -- Figure out the domain specific flags
  --
  if domain == "yahoo.ie" then
    internalState.strIntFlag = globals.strYahooIe
  elseif domain == "yahoo.it" then
    internalState.strIntFlag = globals.strYahooIt
  elseif domain == "yahoo.ca" then
    internalState.strIntFlag = globals.strYahooCa
  elseif domain == "yahoo.co.id" then
    internalState.strIntFlag = globals.strYahooId
  elseif domain == "yahoo.co.in" then
    internalState.strIntFlag = globals.strYahooIn
  elseif domain == "yahoo.fr" then
    internalState.strIntFlag = globals.strYahooFr
  elseif domain == "yahoo.de" then
    internalState.strIntFlag = globals.strYahooDe
  elseif domain == "yahoo.co.uk" then
    internalState.strIntFlag = globals.strYahooUk
  elseif domain == "yahoo.com.mx" then
    internalState.strIntFlag = globals.strYahooMx
  elseif domain == "yahoo.co.kr" then
    internalState.strIntFlag = globals.strYahooKr
  elseif domain == "yahoo.com.tw" then
    internalState.strIntFlag = globals.strYahooTw
  elseif domain == "yahoo.com.au" then
    internalState.strIntFlag = globals.strYahooAu
  elseif domain == "yahoo.no" then
    internalState.strIntFlag = globals.strYahooNo
  elseif domain == "yahoo.se" then
    internalState.strIntFlag = globals.strYahooSe
  else
    internalState.strIntFlag = globals.strYahooUs
  end
  
  -- Get the folder
  --
  local mbox = (freepops.MODULE_ARGS or {}).folder or globals.strInbox
  if mbox ~= globals.strInbox then
    local str = string.match(globals.strInboxPat, "(" .. mbox .. ")")
    if str ~= nil then
      mbox = globals.strInbox
    else
      str = string.match(globals.strBulkPat, "(" .. mbox .. ")")
      if str ~= nil then
        mbox = globals.strBulk
      else
        str = string.match(globals.strTrashPat, "(" .. mbox .. ")")
        if str ~= nil then
          mbox = globals.strTrash
        else
          str = string.match(globals.strSentPat, "(" .. mbox .. ")")
          if str ~= nil then
            mbox = globals.strSent
          else
            str = string.match(globals.strDraftPat, "(" .. mbox .. ")")
            if str ~= nil then 
              mbox = globals.strDraft
            end
          end
        end
      end
    end
  end
  
  mbox = string.gsub(mbox, " ", "+") 
  internalState.strMBox = mbox

  -- Get the view to use in STAT (ALL, UNREAD or FLAG)
  --
  local strView = (freepops.MODULE_ARGS or {}).view or "All"
  local str = string.match(strView, globals.strViewAllPat)
  if str ~= nil then
    internalState.strView = globals.strViewAll
  else
    str = string.match(strView, globals.strViewUnreadPat)
    if str ~= nil then
      internalState.strView = globals.strViewUnread
    else
      internalState.strView = globals.strViewFlagged
    end
  end

  -- If the flag markunread=1 is set, then we will mark all messages
  -- that we pull as unread when done.
  --
  local val = (freepops.MODULE_ARGS or {}).markunread or 0
  if val == "1" then
    log.dbg("Yahoo: All messages pulled will be marked unread.")
    internalState.bMarkMsgAsUnread = true
  end

  val = (freepops.MODULE_ARGS or {}).nossl or 0
  if val == "1" then
    log.dbg("Yahoo: SSL is disabled.")
    internalState.bNoSSL = true
  end

  -- If the flag emptyTrash is set to 1 ,
  -- the trash will be emptied on 'quit'
  --
  val = (freepops.MODULE_ARGS or {}).emptytrash or 0
  if val == "1" then
    log.dbg("Yahoo: Trash folder will be emptied on exit.")
    internalState.bEmptyTrash = true
  end

  -- If the flag emptyBulk is set to 1 ,
  -- the trash will be emptied on 'quit'
  --
  val = (freepops.MODULE_ARGS or {}).emptybulk or 0
  if val == "1" then
    log.dbg("Yahoo: Bulk folder will be emptied on exit.")
    internalState.bEmptyBulk = true
  end

  -- If the flag maxmsgs is set,
  -- STAT will limit the number of messages to the flag
  --
  val = (freepops.MODULE_ARGS or {}).maxmsgs or 0
  if tonumber(val) > 0 then
    log.dbg("Yahoo: A max of " .. val .. " messages will be downloaded.")
    internalState.statLimit = tonumber(val)
  end

  return POPSERVER_ERR_OK
end

-- Perform login functionality
--
function pass(pstate, password)

  -- Store the password
  --
  internalState.strPassword = password

  -- Get a session
  --
  local sessID = session.load_lock(hash())

  -- See if we already have a session.  We want to prevent
  -- multiple sessions for a given account
  --
  if sessID ~= nil then
    -- Session exists
    -- This code is copied from example.  It doesn't make sense to me.
    --
  
    -- Check to see if it is locked
    -- Why "\a"?
    --
    if sessID == "\a" then
      log.dbg("Error: Session locked - Account: " .. internalState.strUser .. 
        "@" .. internalState.strDomain)
      return POPSERVER_ERR_LOCKED
    end
	
    -- Load the session which looks to be a function pointer
    --
    local func, err = loadstring(sessID)
    if not func then
      log.err("Unable to load saved session (Account: " ..
        internalState.strUser .. "@" .. internalState.strDomain .. "): ".. tostr(err))
      return loginYahoo()
    end
		
    log.dbg("Session loaded - Account: " .. internalState.strUser .. 
      "@" .. internalState.strDomain)

    -- Execute the function saved in the session
    --
    func()

    internalState.logger:info("user: ".. internalState.strUser ..
          "@" .. internalState.strDomain .. "\n" .. "info: session loaded")
		
    return POPSERVER_ERR_OK
  else
    -- Create a new session by logging in
    --
    return loginYahoo()
  end
end

-- Quit abruptly
--
function quit(pstate)
  session.unlock(hash())
  return POPSERVER_ERR_OK
end

-- Update the mailbox status and quit
--
function quit_update(pstate)
  -- Make sure we aren't jumping the gun
  --
  local retCode = stat(pstate)
  if retCode ~= POPSERVER_ERR_OK then 
    return retCode 
  end

  if (internalState.bNewGUI == true) then
    deleteMsgs(pstate)

    if internalState.bEmptyTrash == true then
      emptyFolder(globals.strTrash)
    end  

    if internalState.bEmptyBulk == true then
      emptyFolder(globals.strBulkNew)
    end

    session.save(hash(), serialize_state(), session.OVERWRITE)
    session.unlock(hash())

    log.dbg("Session saved - Account: " .. internalState.strUser .. 
      "@" .. internalState.strDomain)

    return POPSERVER_ERR_OK
  end

  -- Local Variables
  --
  local browser = internalState.browser
  local cmdUrl = nil
  local postdata = ""
  local cnt = get_popstate_nummesg(pstate)
  local dcnt = 0

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      local uidl = get_mailmessage_uidl(pstate, i)
      local msgid = internalState.msgids[uidl]
	  if internalState.classicType == "mc" then
	    postdata = postdata .. "mid=" .. msgid .. "&"
	  else
        postdata = postdata .. "Mid=" .. msgid .. "&"
	  end
      dcnt = dcnt + 1
    end
  end

  -- We don't have a stat cache
  --
  if (internalState.strStatCache == nil) then
    log.dbg("Yahoo - unable to retrieve the crumb value.")
    return POPSERVER_ERR_OK
  end

  -- Let's get the crumb value
  --
  local strCrumb = string.match(internalState.strStatCache, globals.strRegExpCrumb)
  if strCrumb == nil then
    log.err("Yahoo - unable to parse out crumb value.  Deletion will fail, Body: " .. 
      internalState.strStatCache)
    return POPSERVER_ERR_OK
  end

  -- We have things to delete, let's do it!
  --
  if (dcnt > 0) then
    if (internalState.classicType ~= "mc") then
      -- Lets get the form variables
      --
      local name, value  
      for name, value in string.gfind(internalState.strStatCache, globals.strHiddenItems) do
        postdata = postdata .. name .. "=" .. curl.escape(value) .. "&" 
      end
      postdata = string.gsub(postdata, "DEL=&", "DEL=1&")
      postdata = postdata .. ".crumb=" .. strCrumb
   
      -- Get the url to post to
      --
      cmdUrl = string.match(internalState.strStatCache, globals.strDeletePostPat)
      if (cmdUrl == nil) then 
        log.err("Yahoo - unable to parse out delete url.  Deletion will fail, Body: " .. 
          internalState.strStatCache)
        return POPSERVER_ERR_OK
      end
      cmdUrl = internalState.strMailServer .. cmdUrl
    else
	  cmdUrl = string.format(globals.strCmdDeleteMC, internalState.strMailServer,
        internalState.classicType, internalState.strMBox) .. strCrumb
	end
	
    -- Do it!
    -- 
    log.dbg("Yahoo - Sending delete url: " .. cmdUrl .. ", data: " .. postdata)
    browser:post_uri(cmdUrl, postdata)
  end

  -- Empty the trash
  --
  local strAll = string.match(internalState.strStatCache, globals.strEmptyAllPat)
  if internalState.bEmptyTrash then
    if strAll ~= nil then
	  if (internalState.classicType == "mc") then
        cmdUrl = string.format(globals.strCmdEmptyTrashMC, internalState.strMailServer, 
		  internalState.classicType) .. strAll
	  else
        cmdUrl = string.format(globals.strCmdEmptyTrash, internalState.strMailServer, 
		  internalState.classicType) .. strAll
	  end
      log.dbg("Sending Empty Trash URL: ".. cmdUrl)
      local body, err = browser:get_uri(cmdUrl)
      if not body or err then
        log.err("Error when trying to empty the trash with url: ".. cmdUrl)
      end
    else
      log.err("Cannot empty trash - crumb not found")
    end
  end

  -- Empty the bulk folder
  --
  if internalState.bEmptyBulk then
    if strAll ~= nil then
	  if (internalState.classicType == "mc") then
		cmdUrl = string.format(globals.strCmdEmptyBulkMC, internalState.strMailServer,
			internalState.classicType) .. strAll
	  else
		cmdUrl = string.format(globals.strCmdEmptyBulk, internalState.strMailServer,
			internalState.classicType) .. strAll
	  end
      log.dbg("Sending Empty Bulk URL: ".. cmdUrl)
      local body, err = browser:get_uri(cmdUrl)
      if not body or err then
        log.err("Error when trying to empty the bulk with url: ".. cmdUrl)
      end
    else
      log.err("Cannot empty bulk - crumb not found")
    end
  end

  session.save(hash(), serialize_state(), session.OVERWRITE)
  session.unlock(hash())

  log.dbg("Session saved - Account: " .. internalState.strUser .. 
    "@" .. internalState.strDomain)

  return POPSERVER_ERR_OK
end

-- Stat command - Get the number of messages and their size
--
function stat(pstate)

  -- Have we done this already?  If so, we've saved the results
  --
  if internalState.bStatDone then
    return POPSERVER_ERR_OK
  end

  -- If we are using the new gui, use the new stat method
  --
  if internalState.bNewGUI then
    return getSTATList(pstate)
  end

  -- Local variables
  -- 
  local strCmd = globals.strCmdMsgList
  if (internalState.classicType == "mc") then
	strCmd = globals.strCmdMsgListMC
  end
  local browser = internalState.browser
  local nPage = 0
  local nMsgs = 0
  local cmdUrl = string.format(strCmd, internalState.strMailServer,
    internalState.classicType, internalState.strMBox, nPage, internalState.strView, 
	internalState.strView);

  -- Keep a list of IDs that we've seen.  With yahoo, their message list can 
  -- show messages that we've already seen.  This, although a bit hacky, will
  -- keep the unique ones.  We'll need to search the table on every message which
  -- really sucks!
  --
  local knownIDs = {}

  -- Force Yahoo to update
  --
  local body, err = browser:get_uri(globals.strMailPage)

  -- Debug Message
  --
  log.dbg("Stat URL: " .. cmdUrl);
		
  -- Initialize our state
  --
  set_popstate_nummesg(pstate, nMsgs)

  -- Local function to process the list of messages, getting id's and sizes
  --
  local function funcProcess(body)
    -- Find out if there are any messages
    -- 
    local nomesg = string.match(body, globals.strMsgListNoMsgPat)
	local nomesgMC = string.match(body, globals.strMsgListNoMsgPatMC)
    if (nomesg == nil and internalState.classicType ~= "mc") then
      return true, nil
	elseif (nomesgMC ~= nil and internalState.classicType == "mc") then
	  return true, nil
    end

    -- Find only the HTML containing the message list
    --
    local subBody = string.match(body, globals.strMsgListHTMLPattern)
    if (subBody == nil) then
      log.say("Yahoo Module needs to fix it's message list pattern matching.")
      return false, nil
    end

    -- Tokenize out the message ID and size for each item in the list
    --    
    local items = mlex.match(subBody, globals.strMsgLineLitPattern, globals.strMsgLineAbsPattern)
    log.dbg("Stat Count: " .. items:count())

    -- Remember the count
    --
    local cnt = items:count()
    if cnt == 0 then
      return true, nil
    end 
		
    -- Cycle through the items and store the msg id and size
    --
    for i = 1, cnt do
      local msgid = items:get(0, i - 1)
      local size = items:get(1, i - 1)

      if (internalState.statLimit ~= nil and nMsgs >= internalState.statLimit) then
        return true, nil
      end

      if not msgid or not size then
        log.say("Yahoo Module needs to fix it's individual message list pattern matching.")
        return nil, "Unable to parse the size and uidl from the html"
      end

      -- Get the message id.  It's a series of a numbers followed by
      -- an underscore repeated.  
      --
      msgid = string.match(msgid, globals.strMsgIDPattern) or string.match(msgid, globals.strMsgIDMCPattern) 
      local uidl = string.gsub(msgid, "_[^_]-_[^_]-_", "_000_000_", 1);
      uidl = string.sub(uidl, 1, 60)

      local bUnique = true
      for j = 0, nMsgs do
        if knownIDs[j + 1] == msgid then
          bUnique = false
          break
        end        
      end

      -- Convert the size from it's string (4k or 821b) to bytes
      -- First figure out the unit (KB or just B)
      --
      local kbUnit = string.match(size, "([Kk])")
	  local mbUnit = string.match(size, "([Mm])")
      size = string.match(size, "([%d]+)[KkMmbB]")
      if kbUnit then 
        size = math.max(tonumber(size), 0) * 1024
  	  elseif mbUnit then
        size = math.max(tonumber(size), 0) * 1024 * 1024
      else
        size = math.max(tonumber(size), 0)
      end

      -- Save the information
      --
      if bUnique == true then
        nMsgs = nMsgs + 1
        log.dbg("Processed STAT - Msg: " .. nMsgs .. ", UIDL: " .. uidl .. ", Size: " .. size)
        set_popstate_nummesg(pstate, nMsgs)
        set_mailmessage_size(pstate, nMsgs, size)
        set_mailmessage_uidl(pstate, nMsgs, uidl)
        knownIDs[nMsgs] = msgid
        internalState.msgids[uidl] = msgid
       end
    end
		
    return true, nil
  end 

  -- Local Function to check for more pages of messages.  If found, the 
  -- change the command url
  --
  local function funcCheckForMorePages(body) 
    if internalState.statLimit ~= nil and internalState.statLimit <= nMsgs then
      return true
    end

    -- Look in the body and see if there is a link for a previous page
    -- If so, change the URL
    --
    local nextURL = string.match(body, globals.strMsgListPrevPagePattern)
    if nextURL ~= nil then
      cmdUrl = internalState.strMailServer .. nextURL
      return false
    else
	  nextURL = string.match(body, globals.strMsgListNextPagePatternMC)
	  if (nextURL ~= nil) then
	    cmdUrl = internalState.strMailServer  .. internalState.classicType .. "/" .. nextURL
	    return false
	  end
	
      return true
    end
  end

  -- Local Function to get the list of messages
  --
  local function funcGetPage()  
    -- Debug Message
    --
    log.dbg("Debug - Getting page: ".. cmdUrl)

    -- Get the page and check to see if we got results
    --
    local body, err = browser:get_uri(cmdUrl)
    if body == nil then
      return body, err
    end

    -- Is the session expired
    --
    local strSessExpr = string.match(body, globals.strRetLoginSessionExpired)
    if strSessExpr ~= nil then
      -- Invalidate the session
      --
      internalState.bLoginDone = nil
      session.remove(hash())

      -- Try Logging back in
      --
      local status = loginYahoo()
      if status ~= POPSERVER_ERR_OK then
        return nil, "Session expired.  Unable to recover"
      end
	
      -- Reset the local variables		
      --
      browser = internalState.browser
      cmdUrl = string.format(strCmd, internalState.strMailServer,
        internalState.classicType, internalState.strMBox, nPage, internalState.strView, 
		internalState.strView);

      -- Retry to load the page
      --
      browser:get_uri(cmdUrl)
    end
		
    internalState.strStatCache = body
    return body, err
  end


  -- Run through the pages and pull out all the message pieces from
  -- all the message lists
  --
  if not support.do_until(funcGetPage, funcCheckForMorePages, funcProcess) then
    log.err("STAT Failed.")
    session.remove(hash())
    return POPSERVER_ERR_UNKNOWN
  end
	
  -- Update our state
  --
  internalState.bStatDone = true
	
  -- Return that we succeeded
  --
  return POPSERVER_ERR_OK
end

-- Fill msg uidl field
--
function uidl(pstate,msg)
  return common.uidl(pstate, msg)
end

-- Fill all messages uidl field
--
function uidl_all(pstate)
  return common.uidl_all(pstate)
end

-- Fill msg size
--
function list(pstate,msg)
  return common.list(pstate, msg)
end

-- Fill all messages size
--
function list_all(pstate)
  return common.list_all(pstate)
end

-- Unflag each message marked for deletion
--
function rset(pstate)
  return common.rset(pstate)
end

-- Mark msg for deletion
--
function dele(pstate,msg)
  return common.dele(pstate, msg)
end

-- Do nothing
--
function noop(pstate)
  return common.noop(pstate)
end

-- Retrieve the message
--
function retr(pstate, msg, data)
  local ret = downloadYahooMsg(pstate, msg, -2, data)
--  log.dbg("RETR returning = "..tostr(ret))
  return ret
--  return POPSERVER_ERR_OK
end

-- Top Command (like retr)
--
function top(pstate, msg, nLines, data)
  return downloadYahooMsg(pstate, msg, nLines, data)
--  return POPSERVER_ERR_OK
end

-- Plugin Initialization - Pretty standard stuff.  Copied from the manual
--  
function init(pstate)
  -- Let the log know that we have been found
  --
  log.dbg(PLUGIN_NAME .. "(" .. PLUGIN_VERSION ..") found!")

  -- Import the freepops name space allowing for us to use the status messages
  --
  freepops.export(pop3server)
	
  -- Load dependencies
  --

  -- Serialization
  --
  require("serial")

  -- Browser
  --
  require("browser")
	
  -- MIME Parser/Generator
  --
  require("mimer")

  -- Common module
  --
  require("common")

  -- Soap
  --
  require("soap.http")

  -- Windows event logging
  --
  require("wel")

  -- Run a sanity check
  --
  freepops.set_sanity_checks()

  -- Let the log know that we have initialized ok
  --
  log.dbg(PLUGIN_NAME .. "(" .. PLUGIN_VERSION ..") initialized!")


  -- Everything loaded ok
  --
  return POPSERVER_ERR_OK
end

-- EOF
-- ************************************************************************** --
