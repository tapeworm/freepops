-- ************************************************************************** --
--  FreePOPs @yahoo.com webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russells@despammed.com>
--  yahoo.it added by Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.0.6"
PLUGIN_NAME = "yahoo.com"
PLUGIN_REQUIRE_VERSION = "0.0.14"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://freepops.sourceforge.net/download.php?file=yahoo.lua"
PLUGIN_HOMEPAGE = "http://freepops.sourceforge.net/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager","Nicola Cocchiaro"}
PLUGIN_AUTHORS_CONTACTS = 
	{"russells (at) despammed (.) com",
         "ncocchiaro (at) users (.) sourceforge (.) net"}
PLUGIN_DOMAINS = {"@yahoo.com","@yahoo.it", "@yahoo.ca"}
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
}
PLUGIN_DESCRIPTIONS = {
	it=[[
Questo plugin vi per mette di leggere le mail che avete in una 
mailbox @yahoo.com, @yahoo.ca o @yahoo.it.
Per usare questo plugin dovete usare il vostro indirizzo email completo come
user name e la vostra password reale come password.]],
	en=[[
This is the webmail support for @yahoo.com, @yahoo.ca and @yahoo.it mailboxes. 
To use this plugin you have to use your full email address as the user 
name and your real password as the password.]]
}

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

local globals = {
  -- Login strings
  -- TODO: Define the HTTPS version
  --
  strLoginURL = "http://login.yahoo.com/config/login",   
  strLoginPostData = ".tries=1&.src=ym&.intl=%s&login=%s&passwd=%s&.persistent=y",
  strLoginFailed = "Login Failed - Invalid User name and password",

  -- Expressions to pull out of returned HTML from Yahoo corresponding to a problem
  --
  strRetLoginBadPassword = "(login_form)",
  strRetLoginSessionExpired = "(error code:  Login)",

  -- Regular expression to extract the mail server
  --

  -- Get the mail server for Yahoo
  --
  strRegExpMailServer = '<a href="(http://[^"]*)ym/',

  -- Get the html corresponding only to the message list
  --
  strMsgListHTMLPattern = '<table id="datatable".*<tbody>(.*)</tbody>.*</table>',

  -- Get the crumb value that is needed for deleting messages and emptying the trash
  --
  strRegExpCrumb = "ET=1&%.crumb=([^&]*)&",

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
  strCmdMsgList = "%sym/ShowFolder?box=%s&Npos=%d&Nview=%s&order=up&sort=date",
  strCmdMsgView = "%sym/ShowLetter?box=%s&PRINT=1&Nhead=f&toc=1&MsgId=%s&bodyPart=%s",
  strCmdDelete = "%sym/ShowFolder?box=%s&DEL=Delete", -- &Mid=%s&.crumb=%s
  strCmdEmptyTrash = "%sym/ShowFolder?ET=1&.crumb=%s&reset=1", -- &box=Inbox
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
  strCrumb = nil,
  strMBox = nil,
  strIntFlag = nil,
  strView = nil,
  bMarkMsgAsUnread = false,
}

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

-- Computes the hash of our state.  Concate the user, domain and mailbox.
--
function hash()
  return (internalState.strUser or "") .. "~" ..
         (internalState.strDomain or "") .. "~"  ..
         (internalState.strMBox or "")
end

-- Issue the command to login to Yahoo
--
function loginYahoo()
  -- Check to see if we've already logged in
  --
  if internalState.loginDone then
    return POPSERVER_ERR_OK
  end

  -- Create a browser to do the dirty work
  --
  internalState.browser = browser.new()

  -- Define some local variables
  --
  local username = internalState.strUser
  local password = internalState.strPassword
  local domain = internalState.strDomain
  local intFlag = internalState.strIntFlag
  local url = globals.strLoginURL
  local post = string.format(globals.strLoginPostData, intFlag, username, password)
  local browser = internalState.browser
	
  -- DEBUG - Set the browser in verbose mode
  --
  -- browser:verbose_mode()

  -- Login to Yahoo
  --
  local body, err = browser:post_uri(url, post)

  -- Error checking
  --

  -- No connection
  --
  if body == nil then
    log.error_print("Login Failed: Unable to make connection")
    return POPSERVER_ERR_AUTH
  end

  -- Check for invalid password
  -- 
  local _, _, str = string.find(body, globals.strRetLoginBadPassword)
  if str ~= nil then
    log.error_print("Login Failed: Invalid Password")
    return POPSERVER_ERR_AUTH
  end

  -- Extract the mail server
  --
  _, _, str = string.find(body, globals.strRegExpMailServer)
  if str == nil then
    log.error_print("Login Failed: Unable to find mail server")
    return POPSERVER_ERR_UNKNOWN
  else
    internalState.strMailServer = str

    -- DEBUG Message
    --
    log.dbg("Yahoo Mail Server: " .. str .. "\n")
  end

  -- Extract the crumb - This is needed for deletion of items
  --
  _, _, str = string.find(body, globals.strRegExpCrumb)
  if str == nil then
    log.error_print("Can't get the 'crumb' value. Will not be able to delete messages.")
    internalState.strCrumb = ""
  else
    internalState.strCrumb = str
  
    -- Debug Message
    -- 
    log.dbg("Yahoo Crumb value: " .. str .. "\n")
  end
  
  -- Note that we have logged in successfully
  --
  internalState.bLoginDone = true
	
  -- Debug info
  --
  log.dbg("Created session (ID: " .. hash() .. ", User: " .. 
    internalState.strUser .. "@" .. internalState.strDomain .. ")\n")

  -- Return Success
  --
  return POPSERVER_ERR_OK
end

-- Download a single message
--
function downloadYahooMsg(pstate, msg, nLines, data)
  -- Make sure we aren't jumping the gun
  --
  local retCode = stat(pstate)
  if retCode ~= POPSERVER_ERR_OK then 
    return retCode 
  end
	
  -- Local Variables
  --
  local browser = internalState.browser
  local uidl = get_mailmessage_uidl(pstate, msg)
  
  local hdrUrl = string.format(globals.strCmdMsgView, internalState.strMailServer,
    internalState.strMBox, uidl, "HEADER");
  local bodyUrl = string.format(globals.strCmdMsgView, internalState.strMailServer,
    internalState.strMBox, uidl, "TEXT");

  -- Get the header
  --
  local headers, _ = browser:get_uri(hdrUrl)

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

    -- Lines requested (-2 means no limited)
    --
    nLinesRequested = nLines,

    -- Lines Received - Not really used for anything
    --
    nLinesReceived = 0
  }
	
  -- Define the callback
  --
  local cb = downloadMsg_cb(cbInfo, data)

  -- Send the headers first to the callback
  --
  cb(headers) 

  -- Start the download on the body
  -- 
  local f, _ = browser:pipe_uri(bodyUrl,cb)
  if not f then
    -- An empty message.  Send the headers anyway
    --
    popserver_callback(headers, data)
  else
    -- Just send an extra carriage return
    --
    popserver_callback("\r\n\0", data)
  end

  -- Do we need to mark the message as unread?
  --
  if internalState.bMarkMsgAsUnread == true then
    local cmdUrl = string.format(globals.strCmdUnread, internalState.strMailServer,
      internalState.strMBox, uidl, internalState.strCrumb);
    browser:get(cmdUrl) -- We don't care about the results.
  end

  return POPSERVER_ERR_OK
end

-- Callback for the retr function
--
function downloadMsg_cb(cbInfo, data)
	
  return function(body, len)
    -- Are we done with Top and should just ignore the chunks
    --
    if (cbInfo.nLinesRequested ~= -2 and cbInfo.nLinesReceived == -1) then
      return 0, nil
    end
  
    -- Clean up the end of line
    --
    body = string.gsub(body, "\n", "\r\n")

    -- Perform our "TOP" actions
    --
    if (cbInfo.nLinesRequested ~= -2) then
      body = cbInfo.strHack:tophack(body, cbInfo.nLinesRequested)

      -- Check to see if we are done and if so, update things
      --
      if cbInfo.strHack:check_stop(cbInfo.nLinesRequested) then
        cbInfo.nLinesReceived = -1;
        if (string.sub(body, -2, -1) ~= "\r\n") then
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

    -- Send the data up the stream
    --
    popserver_callback(body, data)
			
    return len, nil
  end
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
  if domain == "yahoo.it" then
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
    local _, _, str = string.find(globals.strInboxPat, "(" .. mbox .. ")")
    if str ~= nil then
      mbox = globals.strInbox
    else
      _, _, str = string.find(globals.strBulkPat, "(" .. mbox .. ")")
      if str ~= nil then
        mbox = globals.strBulk
      else
        _, _, str = string.find(globals.strTrashPat, "(" .. mbox .. ")")
        if str ~= nil then
          mbox = globals.strTrash
        else
          _, _, str = string.find(globals.strSentPat, "(" .. mbox .. ")")
          if str ~= nil then
            mbox = globals.strSent
          else
            _, _, str = string.find(globals.strDraftPat, "(" .. mbox .. ")")
            if str ~= nil then 
              mbox = globals.strDraft
            end
          end
        end
      end
    end
  end
  
  internalState.strMBox = mbox

  -- Get the view to use in STAT (ALL, UNREAD or FLAG)
  --
  local strView = (freepops.MODULE_ARGS or {}).view or "All"
  local _, _, str = string.find(strView, globals.strViewAllPat)
  if str ~= nil then
    internalState.strView = globals.strViewAll
  else
    _, _, str = string.find(strView, globals.strViewUnreadPat)
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
  if val == 1 then
    interalState.bMarkMsgAsUnread = true
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

  -- Local Variables
  --
  local browser = internalState.browser
  local baseUrl = string.format(globals.strCmdDelete, internalState.strMailServer,
    internalState.strMBox);
  local cmdUrl = baseUrl
  local cnt = get_popstate_nummesg(pstate)
  local dcnt = 0

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      cmdUrl = cmdUrl .. "&Mid=" .. get_mailmessage_uidl(pstate, i)
      dcnt = dcnt + 1

      -- Send out in a batch of 5
      --
      if math.mod(dcnt, 5) == 0 then
        cmdUrl = cmdUrl .. "&.crumb=" .. internalState.strCrumb
        log.dbg("Sending Delete URL: " .. cmdUrl .. "\n")
        local body, err = browser:get_uri(cmdUrl)
        if not body or err then
          log.error_print("Unable to delete messages.\n")
        end
       
        -- Reset the variables
        --
        dcnt = 0
        cmdUrl = baseUrl
      end
    end
  end

  -- Send whatever is left over
  --
  if dcnt > 0 and dcnt < 5 then
    cmdUrl = cmdUrl .. "&.crumb=" .. internalState.strCrumb
    log.dbg("Sending Delete URL: " .. cmdUrl .. "\n")
    local body, err = browser:get_uri(cmdUrl)
    if not body or err then
      log.error_print("Unable to delete messages.\n")
    end
  end

  -- Save and then Free up the session
  --
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
    local _, _, nomesg = string.find(body, globals.strMsgListNoMsgPat)
    if (nomesg == nil) then
      return true, nil
    end

    -- Find only the HTML containing the message list
    --
    local _, _, subBody = string.find(body, globals.strMsgListHTMLPattern)
    if (subBody == nil) then
      log.say("Yahoo Module needs to fix it's message list pattern matching.\n")
      return false, nil
    end

    -- Remove out the attachment link
    --
    --subBody = string.gsub(subBody, '<a href="[^"]+"><img[^>]+></a>', "")

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
      local uidl = items:get(0, i - 1) 
      local size = items:get(1, i - 1)

      if not uidl or not size then
        log.say("Yahoo Module needs to fix it's individual message list pattern matching.\n")
        return nil, "Unable to parse the size and uidl from the html"
      end

      -- Get the message id.  It's a series of a numbers followed by
      -- an underscore repeated.  .
      --
      _, _, uidl = string.find(uidl, globals.strMsgIDPattern) --'value="([%d-_]+)"')

      local bUnique = true
      for j = 0, nMsgs do
        if knownIDs[j + 1] == uidl then
          bUnique = false
          break
        end        
      end

      -- Convert the size from it's string (4k or 821b) to bytes
      -- First figure out the unit (KB or just B)
      --
      local _, _, kbUnit = string.find(size, "([Kk])")
      _, _, size = string.find(size, "([%d]+)[KkbB]")
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
        knownIDs[nMsgs] = uidl
      end
    end
		
    return true, nil
  end 

  -- Local Function to check for more pages of messages.  If found, the 
  -- change the command url
  --
  local function funcCheckForMorePages(body) 
    -- Look in the body and see if there is a link for a previous page
    -- If so, change the URL
    --
    local _, _, nextURL = string.find(body, globals.strMsgListPrevPagePattern)
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
    local _, _, strSessExpr = string.find(body, globals.strRetLoginSessionExpired)
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
        internalState.strMBox, nPage, globals.nViewAll);

      -- Retry to load the page
      --
      return browser:get_uri(cmdUrl)
    end
		
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
  if freepops.dofile("serialize.lua") == nil then 
    return POPSERVER_ERR_UNKNOWN 
  end 

  -- Browser
  --
  if freepops.dofile("browser.lua") == nil then 
    return POPSERVER_ERR_UNKNOWN 
  end
	
  -- MIME Parser/Generator
  --
  if freepops.dofile("mimer.lua") == nil then 
    return POPSERVER_ERR_UNKNOWN 
  end	

  -- Common module
  --
  if freepops.dofile("common.lua") == nil then 
    return POPSERVER_ERR_UNKNOWN 
  end
	
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
