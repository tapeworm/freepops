-- ************************************************************************** --
--  FreePOPs @aol.com webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russells@despammed.com>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.0.1"
PLUGIN_NAME = "aol.com"

-- TODO
-- - Netscape mail support
-- - User defined folder
--

-- Domains supported:  aol.com, aol.com.ar, aol.fr, aol.com.mx, aol.com.au,
--                     aol.de, aol.com.pr, aol.com.br, jp.aol.com, aol.co.uk,
--                     aol.ca, aola.com

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

local globals = {
  -- Server URL
  --
  strLoginUrl = "http://my.screenname.aol.com/_cqr/login/login.psp?siteId=atlasaol&authLev=2&seamless=novl&siteState=",

  -- Login strings
  --
  strLoginPostData = "screenname=%s&password=%s",
  strLoginFailed = "Login Failed - Invalid User name and/or password",

  -- Expressions to pull out of returned HTML from Hotmail corresponding to a problem
  --
  strRetLoginGoodLogin = '(URL=/msglist)',
  strRetLoginSessionNotExpired = "(mail session has expired)",
  
  -- Regular expression to extract the mail server
  --
  
  -- Pattern to extract the URL to go to get the login form
  --
  strLoginPageParamsPattern='goToLoginUrl.*mcRedir."([^"]+)"',

  -- Pattern to pull out the url's we need to go to set some cookies.
  --
  strLoginRetUrlPattern1='LANGUAGE="JavaScript" SRC="(http[^"]*)"',

  -- Extract the server to post the login data to
  --
  strLoginPostUrlPattern1='[Nn][Aa][Mm][Ee]="[^"]*" [Aa][Cc][Tt][Ii][Oo][Nn]="([^"]*)"',
  strLoginPostUrlPattern2='[Tt][Yy][Pp][Ee]="[Hh][Ii][Dd][Dd][Ee][Nn]" [Nn][Aa][Mm][Ee]="([^"]*)" [Vv][Aa][Ll][Uu][Ee]="([^"]*)"',
  strLoginPostUrlPattern3='[Nn][Aa][Mm][Ee]="[^"]*" METHOD="POST" [Aa][Cc][Tt][Ii][Oo][Nn]="([^"]*)"',
  
  -- Used by Stat to pull out the message ID and the size
  --
  strMsgLineIDPattern = 'NAME="msguid" VALUE="([^"]+)"',

  -- Defined Mailbox names - These define the names to use in the URL for the mailboxes
  --
  strInbox = "SU5CT1g=",
  strSpam = "U3BhbQ==",
  strOldbox = "UkVBRA==",
  strTrash = "U2F2ZWQ=",
  strSent = "T1VUQk9Y",

  strInboxPat = "([Nn]ew)",
  strOldboxPat = "([Oo]ld)",
  strSpamPat = "([Ss]pam)",
  strSentPat = "([Ss]ent)",
  strTrashPat = "([Dd]eleted)",

  -- Command URLS
  --
  strCmdMsgList = "http://%s/msglist.adp?folder=%s&start=1",
  strCmdDelete = "http://%s/msglist.adp?folder=%s&start=1&cmd=deletemsgs&cmdnum=%s", --&msguid=X",
  strCmdMsgView = "http://%s/attachment/%s/%s/",
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
  strMBox = nil
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
  local password = internalState.strPassword
  local domain = internalState.strDomain
  local url = globals.strLoginUrl
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
  _, _, url = string.find(body, globals.strLoginPageParamsPattern)
  url = "http://" .. browser:wherearewe() .. url
  body, err = browser:get_uri(url)

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
  body, err = browser:post_uri(url, postdata)

  -- This is where things get a little hokey.  AOL returns a page with three javascript
  -- links that need to be "GET'ed" and then a form that needs to be submitted.  We don't
  -- care at all about the results of the get's other than the cookies...YUM!.
  for value in string.gfind(body, globals.strLoginRetUrlPattern1) do
    _, err = browser:get_uri(value)
  end

  _, _, url = string.find(body, globals.strLoginPostUrlPattern3)
  local postdata = nil
  local name, value  
  for name, value in string.gfind(body, globals.strLoginPostUrlPattern2) do
    if postdata ~= nil then
      postdata = postdata .. "&" .. name .. "=" .. value  
    else
      postdata = name .. "=" .. value 
    end
  end
  body, err = browser:post_uri(url, postdata)

  -- Shouldn't happen but you never know
  --
  if body == nil then
    log.error_print(globals.strLoginFailed)
    return POPSERVER_ERR_AUTH
  end

  -- We should be logged in now! Let's check and make sure.
  --
  local _, _, str = string.find(body, globals.strRetLoginGoodLogin)
  if str == nil then
    log.error_print(globals.strLoginFailed)
    return POPSERVER_ERR_AUTH
  end
  
  -- Save the mail server
  --
  internalState.strMailServer = browser:wherearewe()

  -- DEBUG Message
  --
  log.dbg("AOL/Netscape Server: " .. internalState.strMailServer .. "\n")
  
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
  
  local url = string.format(globals.strCmdMsgView, internalState.strMailServer,
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
  
    -- Clean up the end of line and other things.  In the HTML portion of a message
    -- AOL encodes it with quoted-printable.  Let's fix the easy stuff here.  This will
    -- probably need to be looked at again.  I am sure it will cause issues in the non-HTML
    -- portions of the message.
    --
    body = string.gsub(body, "(Content%-Transfer%-Encoding:) quoted%-printable", "%1 7bit")
    body = string.gsub(body, "=\r\n", "")
    body = string.gsub(body, "=\n", "")
    body = string.gsub(body, "=\r", "")
    body = string.gsub(body, "=[Aa]0", "\n")
    body = string.gsub(body, "=20", " ")
    body = string.gsub(body, "=3[dD]", "=")

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

  -- Get the folder
  --
  local mbox = (freepops.MODULE_ARGS or {}).folder
  if mbox == nil then
    internalState.strMBox = globals.strInbox
    return POPSERVER_ERR_OK
  end

  local _, _, start = string.find(mbox, globals.strSpamPat)
  if start ~= nil then
    internalState.strMBox = globals.strSpam
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strSentPat)
  if start ~= nil then
    internalState.strMBox = globals.strSent
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strTrashPat)
  if start ~= nil then
    internalState.strMBox = globals.strTrash
    return POPSERVER_ERR_OK
  end

  _, _, start = string.find(mbox, globals.strOldboxPat)
  if start ~= nil then
    internalState.strMBox = globals.strOldbox
    return POPSERVER_ERR_OK
  end

  -- TODO - set the other mailbox here and find it
  -- when we log in.
  -- 

  -- Defaulting to the inbox
  --
  log.say("Unable to figure out the mailbox specified.  Defaulting to the Inbox.\n")
  internalState.strMBox = globals.strInbox
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
  local cmdCookie = browser:get_cookie('COMMAND')

  local cmdUrl = string.format(globals.strCmdDelete, internalState.strMailServer, 
    internalState.strMBox, cmdCookie.value)
  local baseUrl = cmdUrl
  

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      cmdUrl = cmdUrl .. "&msguid=" .. get_mailmessage_uidl(pstate, i) 
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
  local nMsgs = 0
  local cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
    internalState.strMBox);
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
    -- Cycle through the items and store the msg id.  AOL doesn't list the size
    -- We'll just return the same value for every message.
    for uidl in string.gfind(body, globals.strMsgLineIDPattern) do
      -- Hard Code the size.
      --
      local size = 4096

      -- Save the information
      --
      nMsgs = nMsgs + 1
      log.dbg("Processed STAT - Msg: " .. nMsgs .. ", UIDL: " .. uidl .. ", (hard coded) Size: " .. size)
      set_popstate_nummesg(pstate, nMsgs)
      set_mailmessage_size(pstate, nMsgs, size)
      set_mailmessage_uidl(pstate, nMsgs, uidl)
    end
    
    return true, nil
  end 

  -- Local Function to check for more pages of messages.  AOL lists all
  -- its messages on one page.
  --
  local function funcCheckForMorePages(body) 
    return true
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
        internalState.strMBox);

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
