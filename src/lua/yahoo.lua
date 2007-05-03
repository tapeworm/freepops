-- ************************************************************************** --
--  FreePOPs @yahoo.com webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russells@despammed.com>
--  yahoo.it added by Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
--  yahoo.ie added by Bruce Williamson <aztrix@yahoo.com>
--  Contributions by Przemyslaw Wroblewski <przemyslaw.wroblewski@gmail.com>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.1.9j"
PLUGIN_NAME = "yahoo.com"
PLUGIN_REQUIRE_VERSION = "0.2.0"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://www.freepops.org/download.php?module=yahoo.lua"
PLUGIN_HOMEPAGE = "http://www.freepops.org/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager","Nicola Cocchiaro"}
PLUGIN_AUTHORS_CONTACTS = 
	{"russells (at) despammed (.) com",
         "ncocchiaro (at) users (.) sourceforge (.) net"}
PLUGIN_DOMAINS = {"@yahoo.com", "@yahoo.ie", "@yahoo.it", "@yahoo.ca", "@rocketmail.com", "@yahoo.com.ar",
                  "@yahoo.co.in", "@yahoo.com.tw", "@yahoo.co.uk", "@yahoo.com.cn",
                  "@yahoo.es", "@yahoo.de", "@talk21.com", "@btinternet.com", "@yahoo.com.au",
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
  strRegExpMailServer = '(http://[^/]+/)ym/',
  
  -- Redirect site on login
  --
  strRegExpMetarefresh  = 'window.location.replace%("([^"]*)"',

  -- Get the html corresponding only to the message list
  --
  strMsgListHTMLPattern = '<table id="datatable".*<tbody>(.*)</tbody>.*</table>',

  -- Get the crumb value that is needed for deleting messages and emptying the trash
  --
  strRegExpCrumb = '<input type=hidden name=".crumb" value="([^"]+)">',

  -- Delete Form hidden items
  --
  strHiddenItems = '<input type="hidden" name="([^"]+)".- value="([^"]-)">',
  strDeletePostPat = '<form name=messageList method=post action="/([^"]+)">',

  -- Mark unread url
  -- 
  strMsgMarkUnreadPat = '<a href="/(ym[^"]*UNR=1[^"]*)">',

  -- Pattern to determine if we have no messages.  If this is found, we have messages.
  --
  strMsgListNoMsgPat = "(<tbody>)",

  -- Used by Stat to pull out the message ID and the size
  --
  strMsgLineLitPattern = ".*<td>.*<a>.*</a>.*</td>.*<td>.*</td>.*<td>.*</td>.*</tr>",
  strMsgLineAbsPattern = "O<O>O<X>O<O>O<O>O<O>O<O>O<O>X<O>O<O>",

  -- MSGID Pattern
  -- 
  strMsgIDPattern = 'MsgId=([^&]*)&',

  -- Pattern used by Stat to get the next page in the list of messages
  --
  strMsgListPrevPagePattern = '<a href="/(ym[^"]*previous=1[^"]*)">',

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
  strCmdMsgList = "%sym/ShowFolder?box=%s&Npos=%d&Nview=%s&order=up&sort=date&reset=1&Norder=up",
  strCmdMsgView = "%sym/ShowLetter?box=%s&PRINT=1&Nhead=f&toc=1&MsgId=%s&bodyPart=%s",
  strCmdMsgWebView = "%sym/ShowLetter?box=%s&MsgId=%s",
  strCmdEmptyTrash = "%sym/ShowFolder?ET=1&", 
  strCmdEmptyBulk = "%sym/ShowFolder?EB=1&", 
  strCmdUnread = "%sym/ShowLetter?box=%s&MsgId=%s&.crumb=%s&UNR=1",

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

  -- New Interface pieces
  --
  bNewGUI = false,
  strWebSrvUrl = nil,
  strGSS = nil,
}

-- ************************************************************************** --
--  Temporary functions for debugging and fixing CRLF bug
-- ************************************************************************** --

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
local ENABLE_LOGRAW = false

-- The platform dependent End Of Line string
-- e.g. this should be changed to "\n" under UNIX, etc.
local EOL = "\r\n"

-- The raw logging function
--
log = log or {} -- fast hack to make the xml generator happy
log.raw = function ( line, data )
  if not ENABLE_LOGRAW then
    return
  end

  local out = assert(io.open("log_raw.txt", "ab"))
  out:write( EOL .. os.date("%c") .. " : " )
  out:write( line )
  if data ~= nil then
    out:write( EOL .. "--------------------------------------------------" .. EOL )
    out:write( data )
    out:write( EOL .. "--------------------------------------------------" )
  end
  assert(out:close())
end

-- Returns "data" with "{LF}" prefixing all \n and "{CR}" prefixing all \r,
--   so hex viewing for those bytes isn't necessary.
--
function showCRLF( data )
  local str = data
  
  if (str == nil) then
    return str
  end

  str = string.gsub(str, "\n", "{LF}\n")
  str = string.gsub(str, "\r", "{CR}\r")
  return str
end

-- Returns "data" with all single \r and \n replaced by \r\n
--
function fixCRLF( data )
  local str = data

  if (str == nil) then
    return str
  end

  -- temporarily convert proper ending to \n
  --
  str = string.gsub(str, "\r\n", "\n")
  str = string.gsub(str, "\r", "\n") -- should we worry about embedded \r?
  str = string.gsub(str, "\n", "\r\n")
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
		internalState.browser:serialize("internalState.browser")
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
    log.dbg("Detected New Version of the Yahoo interface!\n")
    log.raw("Detected New Version of the Yahoo interface!\n")
    log.dbg("Yahoo Mail Server: " .. server .. "\n")

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

  log.raw( "Entering loginYahoo()" )

  if internalState.loginDone then
    return POPSERVER_ERR_OK
  end

  -- Create a browser to do the dirty work (It must be set to IE 6.0)
  --
  internalState.browser = browser.new("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; {02ABE9F9-C33D-95EA-0C84-0B70CD0AC3F8}; .NET CLR 1.1.4322)")
  local SSLEnabled = browser.ssl_enabled()

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
  local body, err = browser:get_uri(globals.strLoginPage)
  
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
  body, err = browser:post_uri(url, post)

  -- Check for redirect
  --
  local str = string.match(body, globals.strRedirectNew)
  if (str ~= nil) then
    body, err = browser:get_uri(str)
  end

  local bNewGui = checkForNewGUI(browser, body)

  if (bNewGui == true) then
    return loginNewYahoo(browser, body) 
  end

  -- Do some error checking
  --
  if (body == nil) then
    -- No connection
    --
    log.error_print("Login Failed: Unable to make connection")
    return POPSERVER_ERR_NETWORK
  end

  local str = string.match(body, '<input type="text" id="secword" name=".secword"')
  if (str ~= nil) then
    log.error_print("Login Failed: Yahoo is using an image verification.  Please login through the web.")
    return POPSERVER_ERR_NETWORK
  end

  -- Check for invalid password
  -- 
  local str = string.match(body, globals.strRetLoginBadPassword)
  if str ~= nil then
    log.raw("------ Returned Page saying invalid password ------\n")
    log.raw(body)
    log.raw("------ End Page saying invalid password -------\n")
    log.error_print("Login Failed: Invalid Password")
    return POPSERVER_ERR_AUTH
  end

  -- Extract the mail server
  --
  local str = string.match(body, globals.strRegExpMailServer)
  if str == nil then
    log.error_print("Login Failed: Unable to find mail server")
    log.raw("Unable to find mail server: " .. body)
    return POPSERVER_ERR_UNKNOWN
  else
    internalState.strMailServer = str
  end

  -- If we are using HTTPS, we need to look for the meta-refresh link
  -- returned by the login response and go to it.
  if (challengeCode ~= nil) then
    str = string.match(body, globals.strRegExpMetarefresh)
    if (str ~= nil) then
      body, err = browser:get_uri(str)
      
      -- Here's the other check (SSL) for the beta interface
      --
      bNewGui = checkForNewGUI(browser, body)
      if (bNewGui == true) then
        return loginNewYahoo(browser, body) 
      end
    end
  end
    
  -- DEBUG Message
  --
  log.dbg("Yahoo Mail Server: " .. internalState.strMailServer .. "\n")

  -- Note that we have logged in successfully
  --
  internalState.bLoginDone = true
	
  -- Debug info
  --
  log.dbg("Created session for " .. 
    internalState.strUser .. "@" .. internalState.strDomain .. "\n")

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
    log.error_print("Yahoo - unable to parse out crumb value.  Deletion will fail.")
    log.raw("Yahoo - unable to parse out crumb value.  Deletion will fail, Body: " .. 
      body)
    return POPSERVER_ERR_UNKNOWN
  end
  log.dbg("Crumb Value: " .. str)
  internalState.strCrumb = str

  -- Get the Web Service Url
  --
--  local str = string.match(body, globals.strRegExpWebSrvUrl)
--  if str == nil then
--    log.error_print("Yahoo - unable to parse out web service Url.")
--    log.raw("Yahoo - unable to parse out web service value.  Body: " .. 
--      body)
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
    internalState.strUser .. "@" .. internalState.strDomain .. "\n")

  -- Return Success
  --
  return POPSERVER_ERR_OK
end

-- Download a single message
--
function downloadYahooMsg(pstate, msg, nLines, data)
  -- Make sure we aren't jumping the gun
  --
  
  log.raw("Entering downloadYahooMsg")
  
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
  if internalState.bNewGUI == false then
    msgid = internalState.msgids[uidl]
    hdrUrl = string.format(globals.strCmdMsgView, internalState.strMailServer,
      internalState.strMBox, msgid, "HEADER");
    bodyUrl = string.format(globals.strCmdMsgView, internalState.strMailServer,
      internalState.strMBox, msgid, "TEXT");

    log.raw("hdrUrl = " .. hdrUrl)
    log.raw("bodyUrl = " .. bodyUrl)
  end

  -- Get the header
  --
  local headers
  if internalState.bNewGUI then
    headers = getMsgHdr(pstate, uidl)
  else
    headers, _ = browser:get_uri(hdrUrl)
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

  -- Remove the quote-printed encoding line from the header
  --
  headers = string.gsub(headers, "Content%-Transfer%-Encoding: quoted%-printable%s+", "");
  --headers = string.gsub(headers, "charset=%"UTF%-8%", "charset=%"us%-ascii%"");

  -- Send the headers first to the callback
  --
  if (internalState.bNewGUI ~= true) then
    cb(headers) 
  else
    headers = string.gsub(headers, "\n", "\r\n")
    headers = string.gsub(headers, "\r\n$", "")
  end

  -- Start the download on the body
  -- 
  if (internalState.bNewGUI) then
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
        popserver_callback(s,data)
      end, cbInfo.inlineids)
  elseif (nLines ~= 0) then  
    local f, _ = browser:pipe_uri(bodyUrl,cb)
    if not f then
      -- An empty message.  Send the headers anyway
      --
      log.dbg("Empty message")
    else
      -- Just send an extra carriage return
      --
      log.dbg("Message Body has been processed.")
      if (cbInfo.strBuffer ~= "\r\n") then
        log.dbg("Message doesn't end in CRLF, adding to prevent client timeout.")
        popserver_callback("\r\n\0", data)
      end
    end
  end

  -- Do we need to mark the message as unread?
  --
  if internalState.bMarkMsgAsUnread == true then
    if internalState.bNewGUI then
      log.dbg("Marking as message: " .. uidl .. " as unread");
      markMsgUnread(uidl)
    else
      local cmdUrl = string.format(globals.strCmdMsgWebView, internalState.strMailServer,
        internalState.strMBox, msgid);
      local str, _ = browser:get_uri(cmdUrl) 
      str = string.match(str, globals.strMsgMarkUnreadPat)
      if str == nil then
        log.warn("Unable to get the url for marking message as unread.")
      else
        cmdUrl = internalState.strMailServer .. str;
        log.dbg("Marking as message: " .. msgid .. " as unread, url: " .. cmdUrl);
        browser:get_uri(cmdUrl) -- We don't care about the results.
      end
    end
  end

  log.raw("Exiting downloadYahooMsg")

  return POPSERVER_ERR_OK
end

-- Callback for the retr function
--
function downloadMsg_cb(cbInfo, data)
	
  return function(body, len)

    log.raw("Entering downloadMsg_cb generated function")

    log.raw("cbInfo.nLinesRequested = " .. cbInfo.nLinesRequested)
    log.raw("cbInfo.nLinesReceived = " .. cbInfo.nLinesReceived)
    log.raw("cbInfo.strHack:current_lines() = " .. cbInfo.strHack:current_lines())

    -- Are we done with Top and should just ignore the chunks
    --
    if (cbInfo.nLinesRequested ~= -2 and cbInfo.nLinesReceived == -1) then
      log.raw("downloadMsg_cb: return 0, nil")
      return 0, nil
    end
  
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
          log.error_print("Does NOT end in CRLF, adding it!")
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

    log.raw("finished text = ", body)

    -- Send the data up the stream
    --
    popserver_callback(body, data)
			
    log.raw("Exiting downloadMsg_cb generated function")
    
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
--    log.error_print("Unable to parse out the gss value.")
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
  if (ipairs == nil) then
    internalState.bStatDone = true
    return POPSERVER_ERR_OK
  end

  for i, elem in ipairs (ent) do
    if (type(elem) == "table" and elem["tag"] == "messageInfo") then
      local attrs = elem["attr"]
      local size = attrs["size"]     
      local uidl = attrs["mid"]

      -- Save the information
      --
      nMsgs = nMsgs + 1
      log.dbg("Processed STAT - Msg: " .. nMsgs .. ", UIDL: " .. uidl .. ", Size: " .. size)
      set_popstate_nummesg(pstate, nMsgs)
      set_mailmessage_size(pstate, nMsgs, size)
      set_mailmessage_uidl(pstate, nMsgs, uidl)
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
    log.error_print("Invalid header!")
    return nil
  end

  return header
end

function getMsgBody(pstate, uidl, size, cbInfo)
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
  local part = nil
  for i, elem in ipairs (ent[3]) do
    if (type(elem) == "table" and elem["tag"] == "part") then
      part = elem
      local attrs = elem["attr"]
      local partId = attrs["partId"]
      local type = attrs["type"]
      local subtype = attrs["subtype"]
      if (subtype == "plain") then
        local textElem = elem[1]
        local text = textElem[1]
        text = text .. "\n"
        cbInfo.strText = getMsgCallBack(cbInfo, text)
      elseif (subtype == "html") then
        local textElem = elem[1]
        local text = textElem[1]
        text = string.gsub(text, "&amp;", "&")
--        text = string.gsub(text, "(</[^>]+>) ", "%1\r\n") 
        text = text .. "\n"
        cbInfo.strHtml = getMsgCallBack(cbInfo, text)
      elseif (partId == "HEADER" or partId == "TEXT") then
        -- no-op
      else
        local file = attrs["dispParams"]
        local contentId = attrs["contentId"]
        if (file ~= nil) then
          file = string.gsub(file, "^.-=", "")
          local escUidl = string.gsub(uidl, "%+", "%%2B")
          url = string.format(globals.strCmdAttach, internalState.strMailServer,
             internalState.strMBox, escUidl, partId, internalState.strMailServer)
          cbInfo.attachments[file] = getRealAttachmentUrl(url)
          table.insert(cbInfo.attachments, table.getn(cbInfo.attachments) + 1, cbInfo.attachments[file])
          if (contentId ~= nil) then
            contentId = string.sub(contentId, 2, -2)
            cbInfo.inlineids[file] = contentId
            table.insert(cbInfo.inlineids, table.getn(cbInfo.inlineids) + 1, contentId)
          end
        end
      end
    end
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
      table.insert(param, { tag = "mid", uidl })
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
  local h, err = browser:get_head(url, {}, true)
  if (err ~= nil) then
    log.dbg(err)
    return nil
  end
  local x = string.match(h,
                "[Ll][Oo][Cc][Aa][Tt][Ii][Oo][Nn]%s*:%s*([^\r]*)")
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
        "@" .. internalState.strDomain .. "\n")
      return POPSERVER_ERR_LOCKED
    end
	
    -- Load the session which looks to be a function pointer
    --
    local func, err = loadstring(sessID)
    if not func then
      log.error_print("Unable to load saved session (Account: " ..
        internalState.strUser .. "@" .. internalState.strDomain .. "): ".. err)
      return loginYahoo()
    end
		
    log.dbg("Session loaded - Account: " .. internalState.strUser .. 
      "@" .. internalState.strDomain .. "\n")

    -- Execute the function saved in the session
    --
    func()
		
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
      "@" .. internalState.strDomain .. "\n")

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
      postdata = postdata .. "Mid=" .. msgid .. "&"
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
    log.error_print("Yahoo - unable to parse out crumb value.  Deletion will fail.")
    log.raw("Yahoo - unable to parse out crumb value.  Deletion will fail, Body: " .. 
      internalState.strStatCache)
    return POPSERVER_ERR_OK
  end

  -- We have things to delete, let's do it!
  --
  if (dcnt > 0) then
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
      log.error_print("Yahoo - unable to parse out delete url.  Deletion will fail.")
      log.raw("Yahoo - unable to parse out delete url.  Deletion will fail, Body: " .. 
        internalState.strStatCache)
      return POPSERVER_ERR_OK
    end

    -- Do it!
    -- 
    cmdUrl = internalState.strMailServer .. cmdUrl
    log.dbg("Yahoo - Sending delete url: " .. cmdUrl .. ", data: " .. postdata)
    browser:post_uri(cmdUrl, postdata)
  end

  -- Empty the trash
  --
  local strAll = string.match(internalState.strStatCache, globals.strEmptyAllPat)
  if internalState.bEmptyTrash then
    if strAll ~= nil then
      cmdUrl = string.format(globals.strCmdEmptyTrash, internalState.strMailServer) .. strAll
      log.dbg("Sending Empty Trash URL: ".. cmdUrl .."\n")
      local body, err = browser:get_uri(cmdUrl)
      if not body or err then
        log.error_print("Error when trying to empty the trash with url: ".. cmdUrl .."\n")
      end
    else
      log.error_print("Cannot empty trash - crumb not found\n")
    end
  end

  -- Empty the bulk folder
  --
  if internalState.bEmptyBulk then
    if strAll ~= nil then
      cmdUrl = string.format(globals.strCmdEmptyBulk, internalState.strMailServer) .. strAll
      log.dbg("Sending Empty Bulk URL: ".. cmdUrl .."\n")
      local body, err = browser:get_uri(cmdUrl)
      if not body or err then
        log.error_print("Error when trying to empty the bulk with url: ".. cmdUrl .."\n")
      end
    else
      log.error_print("Cannot empty bulk - crumb not found\n")
    end
  end

  session.save(hash(), serialize_state(), session.OVERWRITE)
  session.unlock(hash())

  log.dbg("Session saved - Account: " .. internalState.strUser .. 
    "@" .. internalState.strDomain .. "\n")

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
  local browser = internalState.browser
  local nPage = 0
  local nMsgs = 0
  local cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
    internalState.strMBox, nPage, internalState.strView);

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
  log.dbg("Stat URL: " .. cmdUrl .. "\n");
		
  -- Initialize our state
  --
  set_popstate_nummesg(pstate, nMsgs)

  -- Local function to process the list of messages, getting id's and sizes
  --
  local function funcProcess(body)
    -- Find out if there are any messages
    -- 
    local nomesg = string.match(body, globals.strMsgListNoMsgPat)
    if (nomesg == nil) then
      return true, nil
    end

    -- Find only the HTML containing the message list
    --
    local subBody = string.match(body, globals.strMsgListHTMLPattern)
    if (subBody == nil) then
      log.say("Yahoo Module needs to fix it's message list pattern matching.\n")
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
        log.say("Yahoo Module needs to fix it's individual message list pattern matching.\n")
        return nil, "Unable to parse the size and uidl from the html"
      end

      -- Get the message id.  It's a series of a numbers followed by
      -- an underscore repeated.  
      --
      msgid = string.match(msgid, globals.strMsgIDPattern) --'value="([%d-_]+)"')
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
      size = string.match(size, "([%d]+)[KkbB]")
      if not kbUnit then 
        size = math.max(tonumber(size), 0)
      else
        size = math.max(tonumber(size), 0) * 1024
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
    if internalState.statLimit ~= nil and internalState.statLimit >= nMsgs then
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
      cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
        internalState.strMBox, nPage, internalState.strView);

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
    log.error_print("STAT Failed.\n")
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
  downloadYahooMsg(pstate, msg, -2, data)
  return POPSERVER_ERR_OK
end

-- Top Command (like retr)
--
function top(pstate, msg, nLines, data)
  downloadYahooMsg(pstate, msg, nLines, data)
  return POPSERVER_ERR_OK
end

-- Plugin Initialization - Pretty standard stuff.  Copied from the manual
--  
function init(pstate)
  -- Let the log know that we have been found
  --
  log.dbg(PLUGIN_NAME .. "(" .. PLUGIN_VERSION ..") found!\n")

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

  -- Run a sanity check
  --
  freepops.set_sanity_checks()

  -- Let the log know that we have initialized ok
  --
  log.dbg(PLUGIN_NAME .. "(" .. PLUGIN_VERSION ..") initialized!\n")


  -- Everything loaded ok
  --
  return POPSERVER_ERR_OK
end

-- EOF
-- ************************************************************************** --
