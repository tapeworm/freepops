-- ************************************************************************** --
--  FreePOPs @aol.com webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russells@despammed.com>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.0.8a"
PLUGIN_NAME = "aol.com"
PLUGIN_REQUIRE_VERSION = "0.0.21"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://freepops.sourceforge.net/download.php?file=aol.lua"
PLUGIN_HOMEPAGE = "http://freepops.sourceforge.net/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager"}
PLUGIN_AUTHORS_CONTACTS = {"russells (at) despammed (.) com"}
PLUGIN_DOMAINS = {
"@aol.com","@aol.com.ar","@aol.fr","@aol.com.mx","@aol.com.au","@aol.de",
"@aol.com.pr","@aol.com.br","@jp.aol.com","@aol.com.uk","@aol.ca","@aola.com", 
"@netscape.net", "@aim.com"} 
PLUGIN_PARAMETERS ={ 
	{name="folder", description={
		it=[[La cartella che vuoi ispezionare. Quella di default &egrave; New, gli altri valori possibili sono: Old, Sent, Saved, Spam e Deleted.]],
		en=[[The folder you want to interact with. Default is New, other values are for: Old, Sent, Saved, Spam and Deleted.]]}
	}
}
PLUGIN_DESCRIPTIONS = {
	it=[[
Per usare questo plugin dovrete usare il vostro indirizzo email completo come 
nome utente e la vostra vera password come password.]],
	en=[[
To use
this plugin you have to use your full email address as the username
and your real password as the password.]]
}


-- TODO
-- - User defined folder
--

-- Domains supported:  aol.com, aol.com.ar, aol.fr, aol.com.mx, aol.com.au,
--                     aol.de, aol.com.pr, aol.com.br, jp.aol.com, aol.co.uk,
--                     aol.ca, aola.com, netscape.net, aim.com

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

local globals = {
  -- Server URL
  -- 
  strLoginUrl = "http://my.screenname.aol.com/_cqr/login/login.psp?seamless=novl&sitedomain=beta.webmail.aol.com&lang=en&locale=us&authLev=2&siteState=",
  strLoginAIMUrl = "http://my.screenname.aol.com/_cqr/login/login.psp?mcState=initialized&seamless=novl&sitedomain=mail.aol.com&lang=en&locale=us&authLev=2&siteState=ver%3a1%252c0%26ld%3amail.aol.com",

  -- Login strings
  --
  strLoginPostData = "screenname=%s&password=%s",
  strLoginFailed = "Login Failed - Invalid User name and/or password",

  -- Logout
  --
  strLogout = "http://%s/logout.aspx",

  -- Expressions to pull out of returned HTML from Hotmail corresponding to a problem
  --
  strRetLoginGoodLogin = 'gTargetHost = "([^"]+)"';
  strRetLoginGoodLoginAim = 'gPreferredHost = "([^"]+)"';
  strRetLoginSessionNotExpired = "(mail session has expired)",
  
  -- Regular expression to extract the mail server
  --
  
  -- Pattern to extract the URL to go to get the login form
  --
  strLoginPageParamsPattern='goToLoginUrl.-Redir."([^"]+)"',
  strLoginPageParamsPatternAim = 'snsRedir."([^"]+)".;',

  -- Pattern to pull out the url's we need to go to set some cookies.
  --
  strLoginRetUrlPattern1='LANGUAGE="JavaScript" SRC="(http[^"]*)"',
  
  -- Pattern to find the next page of messages
  --
  strMsgListPrevPagePattern = '<A HREF="([^"]+)" CLASS="msglistbottomnav">Next</A>',

  -- Pattern to extract the version of webmail
  --
  strVersionPattern = 'var VERSION[ ]?=[ ]?"([^"]+)";',

  -- Extract the server to post the login data to
  --
  strLoginPostUrlPattern1='[Mm][Ee][Tt][Hh][Oo][Dd]="[^"]*" [Aa][Cc][Tt][Ii][Oo][Nn]="([^"]*)"',
  strLoginPostUrlPattern2='[Tt][Yy][Pp][Ee]="[Hh][Ii][Dd][Dd][Ee][Nn]" [Nn][Aa][Mm][Ee]="([^"]*)" [Vv][Aa][Ll][Uu][Ee]="([^"]*)"',
  strLoginPostUrlPattern3='[Nn][Aa][Mm][Ee]="[^"]*" [Mm][Ee][Tt][Hh][Oo][Dd]="POST" [Aa][Cc][Tt][Ii][Oo][Nn]="([^"]*)"',
  
  -- Extract the AOL internal id for the user
  --
  strUserIdPattern = "uid:([^&]+)&",

  -- Used by Stat to pull out the message ID and the size
  --
  strMsgLinePattern = 'new parent%.MessageInfo%("([^"]+)",[^,]+,"[^"]+",[^,]+,([^,]+),',

  -- Defined Mailbox names - These define the names to use in the URL for the mailboxes
  --
  strInbox = "New%20Mail", 
  strSpamAOL = "Spam",
  strOldboxAOL = "Old%20Mail",
  strTrashAOL = "Recently%20Deleted",
  strSentAOL = "Sent%20Mail",
  StrSavedAOL = "Saved%20Mail",

  strInboxAim = "Inbox",
  strTrashAim = "Trash",
  strSentAim = "Sent",
  strDraftsAim = "Drafts",
  
  strTrashNetscape = "VHJhc2g=",
  strSentNetscape = "U2VudA==",
  strDraftNetscape = "RHJhZnQ=",

  strInboxPat = "([Nn]ew)",
  strOldboxPat = "([Oo]ld)",
  strSpamPat = "([Ss]pam)",
  strSentPat = "([Ss]ent)",
  strDeletedPat = "([Dd]eleted)",
  strTrashPat = "([Tt]rash)",
  strDraftPat = "([Dd]raft)",
  strSavedPat = "([Ss]aved)",

  -- Base part of a custom folder name
  --
  strCustomFolderBase = "Saved%2F",

  -- Command URLS
  --
  strCmdMsgList = "http://%s/GetMessageList.aspx?user=%s&page=%d&folder=%s&previousFolder=&stateToken=&newMailToken=&version=%s",
  strCmdDelete = "http://%s/rpc_messages.aspx?folder=%s&action=delete&user=%s&version=%s", --&uid=X",
  strCmdMsgView = "http://%s/rfc822.aspx?user=%s&folder=%s&uid=%s",
  strCmdWelcome = "http://%s/MessageList.aspx",

  -- Site IDs
  --
  strAOLID = "atlasaol",
  strNetscapeID = "nscpenusmail",
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
  strSiteId = "",
  strUserId = nil,
  strVersion = "",
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

-- Issue the command to login to AOL
--
function loginAOL()
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
  local password = curl.escape(internalState.strPassword)
  local domain = internalState.strDomain
  local url = globals.strLoginUrl  --string.format(globals.strLoginUrl, internalState.strSiteId)
  if (domain == "aim.com") then
    url = globals.strLoginAIMUrl
  end
  local xml = globals.strFolderQry
  local browser = internalState.browser
	
  -- DEBUG - Set the browser in verbose mode
  --
--  browser:verbose_mode()

  -- Enable SSL
  --
  browser:ssl_init_stuff()

  -- Let the browser know to follow refresh headers
  --
  browser:setFollowRefreshHeader(true)

  -- Retrieve the login page.
  --
  local body, err = browser:get_uri(url)

  -- We need to add a cookie.
  --
  --local c = cookie.parse_cookies("MC_COOKIETEST=YES; path=/", browser:wherearewe())
  browser:add_cookie(url, "MC_COOKIETEST=YES; path=/")

  -- No connection
  --
  if body == nil then
    log.error_print("Login Failed: Unable to make connection")
    return POPSERVER_ERR_NETWORK
  end

  -- The login page sends us to a page that tests cookies and javascript.  We
  -- don't run javascript and thus must do the work here of pulling out the URL that
  -- the javascript would redirect too.
  if domain == "aim.com" then
    _, _, url = string.find(body, globals.strLoginPageParamsPatternAim)
  else
    _, _, url = string.find(body, globals.strLoginPageParamsPattern)
  end
  if (url == nil) then
    log.error_print("Unable to figure out the redirect on the login page.")
    return POPSERVER_ERR_UNKNOWN
  end
  body, err = browser:get_uri(url)

  -- Shouldn't happen but you never know
  --
  if body == nil then
    log.error_print(globals.strLoginFailed)
    return POPSERVER_ERR_NETWORK
  end

  -- We are now at the signin page.  Let's pull out the action of the signin form and
  -- all the hidden variables.  When done, we'll post the data along with the user and password.
  -- 
  _, _, url = string.find(body, globals.strLoginPostUrlPattern1)
  local postdata = nil
  local name, value  
  for name, value in string.gfind(body, globals.strLoginPostUrlPattern2) do
    if postdata ~= nil then
      postdata = postdata .. "&" .. name .. "=" .. value  
    else
      postdata = name .. "=" .. value 
    end
  end
  postdata = postdata .. "&" .. 
    string.format(globals.strLoginPostData, username, password)
  url = "http://" .. browser:wherearewe() .. url
  body, err = browser:post_uri(url, postdata)

  -- This is where things get a little hokey.  AOL returns a page with three javascript
  -- links that need to be "GET'ed" and then a form that needs to be submitted.  We don't
  -- care at all about the results of the get's other than the cookies...YUM!.
  for value in string.gfind(body, globals.strLoginRetUrlPattern1) do
    local body2, err2 = browser:get_uri(value)
    local _, _, cval = string.find(body2, 'hl0ckVal="([^"]+)"')
    if (cval ~= nil) then
      browser:add_cookie(value, "MC_CMP_ESKX=" .. cval .."; domain=.aol.com; path=/")
    end
    _, _, cval = string.find(body2, 'hckVal="([^"]+)"')
    if (cval ~= nil) then
      browser:add_cookie(value, "MC_CMP_ESK=" .. cval .. "; domain=.aol.com; path=/")
    end
  end

  -- Need to redirect
  --
  _, _, url = string.find(body, "checkErrorAndSubmitForm%([^,]+, [^,]+, '([^']+)'")
  if url == nil then
    log.error_print(globals.strLoginFailed)
    return POPSERVER_ERR_AUTH  
  end
  body, err = browser:get_uri(url)

  -- We should be logged in now! Let's check and make sure.
  --
  local str = nil
  if domain == "aim.com" then
    _, _, str = string.find(body, globals.strRetLoginGoodLoginAim)
  else
    _, _, str = string.find(body, globals.strRetLoginGoodLogin)
  end
  if str == nil then
    log.error_print(globals.strLoginFailed)
    return POPSERVER_ERR_AUTH
  end
  
  -- Save the mail server
  --
  internalState.strMailServer = str

  -- DEBUG Message
  --
  log.dbg("AOL/Netscape Server: " .. internalState.strMailServer .. "\n")

  -- Get UserID from cookie
  --
  local cookie = browser:get_cookie('Auth')
  if cookie == nil then 
    log.error_print("Unable to determine AOL internal user id.  The plugin needs to be updated.")
  else
    _, _, internalState.strUserId = string.find(cookie.value, globals.strUserIdPattern)
    if internalState.strUserId == nil then 
      log.error_print("Unable to determine AOL internal user id.  The plugin needs to be updated.")
    end
  end

  -- Get the webmail version
  --
  url = string.format(globals.strCmdWelcome, internalState.strMailServer)
  body, err = browser:get_uri(url)
  _, _, str = string.find(body, globals.strVersionPattern)
  if (str == nil) then 
    internalState.strVersion = "_SRV_1_0_0_12281_"
  else
    internalState.strVersion = str
  end
  log.dbg("AOL webmail version: " .. internalState.strVersion)
  
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
function downloadMsg(pstate, msg, nLines, data)
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
  local url = string.format(globals.strCmdMsgView, internalState.strMailServer, internalState.strUserId,
    internalState.strMBox, uidl);

  -- Debug Message
  --
  log.dbg("Getting message: " .. uidl .. ", URL: " .. url)

  -- Define a structure to pass between the callback calls
  --
  local cbInfo = {
    -- Whether this is the first call of the callback
    --
    bFirstBlock = true,

    -- String hacker
    --
    strHack = stringhack.new(),

    -- Lines requested (-2 means not limited)
    --
    nLinesRequested = nLines,

    -- Lines Received - Not really used for anything
    --
    nLinesReceived = 0
  }
	
  -- Define the callback
  --
  local cb = downloadMsg_cb(cbInfo, data)

  -- Start the download on the body
  -- 
  local f, _ = browser:pipe_uri(url, cb)

  -- To be safe, add a blank line
  --
  popserver_callback("\r\n\0", data)

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
  -- TODO:  mailbox - for now, just inbox
  --
  local domain = freepops.get_domain(username)
  local user = freepops.get_name(username)

  internalState.strDomain = domain
  internalState.strUser = user

  -- Set the site id
  -- 
  if domain == "netscape.net" then
    internalState.strSiteId = globals.strNetscapeID
  else
    internalState.strSiteId = globals.strAOLID
  end

  -- Get the folder
  --
  local mbox = (freepops.MODULE_ARGS or {}).folder
  if mbox == nil then
    if domain == "aim.com" then
      internalState.strMBox = globals.strInboxAim
    else
      internalState.strMBox = globals.strInbox
    end
    return POPSERVER_ERR_OK
  end

  local _, _, start = string.find(mbox, globals.strSpamPat)
  if start ~= nil then
    internalState.strMBox = globals.strSpamAOL
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strSentPat)
  if start ~= nil then
    if domain == "aim.com" then
      internalState.strMBox = globals.strSentAim
    else
      internalState.strMBox = globals.strSentAOL
    end
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strDeletedPat)
  if start ~= nil then
    if domain == "aim.com" then
      internalState.strMBox = globals.strTrashAim
    else
      internalState.strMBox = globals.strTrashAOL
    end
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strTrashPat)
  if start ~= nil then
    internalState.strMBox = globals.strTrashNetscape
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strDraftPat)
  if start ~= nil then
    internalState.strMBox = globals.strDraftAim
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strOldboxPat)
  if start ~= nil then
    internalState.strMBox = globals.strOldbox
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strSavedPat)
  if start ~= nil then
    internalState.strMBox = globals.strSavedAOL
    return POPSERVER_ERR_OK
  end

  -- It's a custom folder
  -- 
  internalState.strMBox = globals.strCustomFolderBase .. mbox
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
      return loginAOL()
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
    return loginAOL()
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
  local cnt = get_popstate_nummesg(pstate)
  local dcnt = 0

  local cmdUrl = string.format(globals.strCmdDelete, internalState.strMailServer, 
    internalState.strMBox, internalState.strUserId, internalState.strVersion)
  local baseUrl = cmdUrl

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      cmdUrl = cmdUrl .. "&uid=" .. get_mailmessage_uidl(pstate, i) 
      dcnt = dcnt + 1

      -- Send out in a batch of 5
      --
      if math.mod(dcnt, 5) == 0 then
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
    log.dbg("Sending Delete URL: " .. cmdUrl .. "\n")
    local body, err = browser:get_uri(cmdUrl)
    if not body or err then
      log.error_print("Unable to delete messages.\n")
    end
  end

  -- Log out
  --
  cmdUrl = string.format(globals.strLogout, internalState.strMailServer)
  browser:get_uri(cmdUrl)

  -- AOL acts retarded if we save the session.  We'll remove it and
  -- force the browser to log out.
  --
  session.remove(hash())
  session.unlock(hash())

  log.dbg("Session removed - Account: " .. internalState.strUser .. 
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
  local nMsgs = 0
  local cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer, internalState.strUserId,
    1, internalState.strMBox, internalState.strVersion);
  local baseUrl = cmdUrl

  -- Debug Message
  --
  log.dbg("Stat URL: " .. cmdUrl .. "\n");
		
  -- Initialize our state
  --
  set_popstate_nummesg(pstate, nMsgs)

  -- Local function to process the list of messages, getting id's and sizes
  --
  local function funcProcess(body)
    -- Cycle through the items and store the msg id and size.  
    ---
    for uidl, size in string.gfind(body, globals.strMsgLinePattern) do
      -- Save the information
      --
      nMsgs = nMsgs + 1
      log.dbg("Processed STAT - Msg: " .. nMsgs .. ", UIDL: " .. uidl .. ", Size: " .. size)
      set_popstate_nummesg(pstate, nMsgs)
      set_mailmessage_size(pstate, nMsgs, size)
      set_mailmessage_uidl(pstate, nMsgs, uidl)
    end
    
    return true, nil
  end 

  -- Local Function to check for more pages of messages.  AOL lists all
  -- its messages on one page (but Netscape does in pages of 25)
  --
  local function funcCheckForMorePages(body) 
    -- Look in the body and see if there is a link for a previous page
    -- If so, change the URL
    --
    local _, _, nextURL = string.find(body, globals.strMsgListPrevPagePattern)
    if nextURL ~= nil then
      cmdUrl = "http://" .. internalState.strMailServer .. "/" .. nextURL
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
    local _, _, strSessExpr = string.find(body, globals.strRetLoginSessionNotExpired)
    if strSessExpr ~= nil then
      -- Debug logging
      --
      log.dbg("Session expired.  Attempting to reconnect - Account: " .. internalState.strUser .. 
        "@" .. internalState.strDomain .. "\n")

      -- Invalidate the session
      --
      internalState.bLoginDone = nil
      session.remove(hash())

      -- Try Logging back in
      --
      local status = loginAOL()
      if status ~= POPSERVER_ERR_OK then
        return nil, "Session expired.  Unable to recover"
      end
	
      -- Reset the local variables		
      --
      browser = internalState.browser
      cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
        internalState.strMBox, internalState.strVersion)

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
  downloadMsg(pstate, msg, -2, data)
  return POPSERVER_ERR_OK
end

-- Top Command (like retr)
--
function top(pstate, msg, nLines, data)
  downloadMsg(pstate, msg, nLines, data)
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
