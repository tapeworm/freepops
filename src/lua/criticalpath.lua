-- ************************************************************************** --
--  FreePOPs criticalpath webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russells@despammed.com>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.0.3a"
PLUGIN_NAME = "criticalpath.lua"
PLUGIN_REQUIRE_VERSION = "0.0.97"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://freepops.sourceforge.net/download.php?file=criticalpath.lua"
PLUGIN_HOMEPAGE = "http://www.freepops.org/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager"}
PLUGIN_AUTHORS_CONTACTS = {"russells (at) despammed (.) com"}
PLUGIN_DOMAINS = {"@canada.com"}
PLUGIN_PARAMETERS = {
	{name="folder", description={
		it=[[La cartella che vuoi ispezionare.]],
		en=[[The folder you want to interact with. Default is Inbox.  The standard 
                     folders are: Inbox, Sent Items, Drafts and Trash]]}
	},

}
PLUGIN_DESCRIPTIONS = {
	it=[[
Per usare questo plugin dovrete usare il vostro indirizzo email completo come 
nome utente e la vostra vera password come password.]],
	en=[[
To use this plugin you have to use your full email address as the username
and your real password as the password.  For support, please post a question to
the forum instead of emailing the author(s).]]
}

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

local globals = {
  -- Server URL
  --
  strLoginUrl = "https://members.canada.com/cc/login.aspx?site=canada&provider=aol&brand=email&returnurl=http://webmail.canada.com",

  -- Login strings
  --
  strLoginPostData = "email_address=%s@%s&password=%s&ibtnLogin.x=0&ibtnLogin.y=0&__VIEWSTATE=%s",
  strLoginFailed = "Login Failed - Invalid User name and/or password",
  strLoginFailedVS = "Login Failed - Unable to retrieve the view state to properly send the login info.",
  strLoginFailedRegExp = "Login Failed - Unable to retrieve the token field: ",

  -- Expressions to pull out of returned HTML corresponding to a problem
  --
  strRetGoodLogin = '(<form name="userLogin")',
  strRetLoginSessionExpired = "(Please select a message to redirect)",
  
  -- Regular expression to extract the mail server
  --

  -- Extract the view state id
  --
  strViewStatePat = '__VIEWSTATE" value="([^"]+)"',
 
  -- Extract the first post login next page
  --
  strLoginGoodNextPage = "content='0;URL=([^']+)'",
  
  -- Get the Token values that is needed for every command
  --
  strRegExpToken = 'var ut="([^"]+)";',
  strRegExpPlan = 'var planname="([^"]+)";',
  strRegExpIpa = 'var ipa="([^"]+)";',

  -- Used by Stat to pull out the message ID and the size
  --
  strMsgLinePattern = 'href="javascript:I%(.(%d+).%);">[^<]+</a>&nbsp;</td>[^<]+<td nowrap="nowrap">[^<]+<[^>]+></td>[^<]+<td>([^k]+)k</td>[^<]+</tr>',

  -- Number of pages
  --
  strNumPagesPat = 'Msgs in total %- page %d+ of (%d+)',

  -- Default mailbox
  --
  strInbox = "Inbox",

  -- Command URLS
  --
  strCmdMsgList = "http://%s/cgi-common/webmail.cgi?cmd=reload_mail&fld=%s",
  strCmdMsgListNextPage = "&pos=%d",
  strCmdDelete = 'http://%s/cgi-common/webmail.cgi',
  strCmdDeletePost = 'folder=%s&get_attach_id=true&dstfld=Trash&cmd=movesel',
  strCmdMsgView = 'http://%s/cgi-common/webmail.cgi/email.mail?cmd=msg_save-%s&folder=%s',
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
  strCrumb = nil,
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

-- Computes the hash of our state.  Concate the user, domain, mailbox and password
--
function hash()
  return (internalState.strUser or "") .. "~" ..
         (internalState.strDomain or "") .. "~"  ..
         (internalState.strMBox or "") .. "~"  ..
	 internalState.strPassword -- this asserts strPassword ~= nil
end

-- Issue the command to login
--
function login()
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
  local url = globals.strLoginUrl
  local browser = internalState.browser
	
  -- DEBUG - Set the browser in verbose mode
  --
--  browser:verbose_mode()

  -- Initialize SSL
  --
  browser:ssl_init_stuff()
  
  -- Retrieve the login page.
  --
  local body, err = browser:get_uri(url)

  -- No connection
  --
  if body == nil then
    log.error_print("Login Failed: Unable to make connection: " .. err)
    return POPSERVER_ERR_NETWORK
  end

  -- Get the View State
  --
  local _, _, str = string.find(body, globals.strViewStatePat)
  if str == nil then
    log.error_print(globals.strLoginFailedVS)
    return POPSERVER_ERR_NETWORK
  end

  -- Create the post string
  --
  local post = string.format(globals.strLoginPostData, username, domain, password, curl.escape(str))

  -- Send the login info
  --
  body, err = browser:post_uri(url, post)
log.dbg(url .. " - " .. post)
  -- No connection
  --
  if body == nil then
    log.error_print("Login Failed: Unable to make connection: " .. err)
    return POPSERVER_ERR_NETWORK
  end

  -- Go through the redirects
  --
  for i = 1, 2 do
    -- Find the next page to go to.  We need to extract some info
    --
    _, _, str = string.find(body, globals.strLoginGoodNextPage)
    if (str == nil) then
      log.error_print(globals.strLoginFailed)
      return POPSERVER_ERR_AUTH
    end
    body, err = browser:get_uri(str)
  end

  -- Save the mail server
  --
  internalState.strMailServer = browser:wherearewe()

  -- Get the pieces that make up the crumb
  --
  _, _, str = string.find(body, globals.strRegExpToken)
  if str == nil then
    log.error_print(globals.strLoginFailedRegExp .. "ut")
    return POPSERVER_ERR_NETWORK
  end
  internalState.strCrumb = str
  _, _, str = string.find(body, globals.strRegExpPlan)
  if str == nil then
    log.error_print(globals.strLoginFailedRegExp .. "planname")
    return POPSERVER_ERR_NETWORK
  end
  internalState.strCrumb = internalState.strCrumb .. str
  _, _, str = string.find(body, globals.strRegExpIpa)
  if str == nil then
    log.error_print(globals.strLoginFailedRegExp .. "ipa")
    return POPSERVER_ERR_NETWORK
  end
  internalState.strCrumb = internalState.strCrumb .. str

  -- DEBUG Message
  --
  log.dbg("CriticalPath Server: " .. internalState.strMailServer .. "\n")
  log.dbg("CriticalPath Crumb value: " .. internalState.strCrumb .. "\n")
  
  -- Note that we have logged in successfully
  --
  internalState.bLoginDone = true
	
  -- Debug info
  --
  log.dbg("Created session for " ..  internalState.strUser .. "@" .. 
    internalState.strDomain .. "\n") 

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
    uidl, internalState.strMBox) .. internalState.strCrumb;

  -- Debug Message
  --
  log.dbg("Getting message: " .. uidl .. ", URL: " .. url)

  -- Define a structure to pass between the callback calls
  --
  local cbInfo = {
    -- String hacker
    --
    strHack = stringhack.new(),

    -- Lines requested (-2 means not limited)
    --
    nLinesRequested = nLines,

    -- Lines Received - Not really used for anything
    --
    nLinesReceived = 0,
  }
	
  -- Define the callback
  --
  local cb = downloadMsg_cb(cbInfo, data)

  -- Start the download on the body
  -- 
  local f, _ = browser:pipe_uri(url, cb)
  if not f then
    -- An empty message.  Throw an error
    --
    return POPSERVER_ERR_NETWORK
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

    -- Fix the EOF's
    --
    body = string.gsub(body, "\r", "");
    body = string.gsub(body, "\n", "\r\n");

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

  -- Get the folder
  --
  local mbox = (freepops.MODULE_ARGS or {}).folder
  if mbox == nil then
    internalState.strMBox = globals.strInbox
  else
    internalState.strMBox = mbox
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
      return login()
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
    return login()
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
  local cmdUrl = string.format(globals.strCmdDelete, internalState.strMailServer)
  local cnt = get_popstate_nummesg(pstate)
  local dcnt = 0
  local post = string.format(globals.strCmdDeletePost, internalState.strMBox) .. internalState.strCrumb

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      local uidl = get_mailmessage_uidl(pstate, i)
      post = post .. "&sel_" .. uidl .. "=on"
      dcnt = dcnt + 1

      -- Send out in a batch of 25
      --
      if math.mod(dcnt, 25) == 0 then
        log.dbg("Sending Delete URL: " .. cmdUrl .. "\n")
        local body, err = browser:post_uri(cmdUrl, post)
       
        -- Reset the variables
        --
        dcnt = 0
        post = string.format(globals.strCmdDeletePost, internalState.strMBox) .. internalState.strCrumb
      end
    end
  end

  -- Send whatever is left over
  --
  if dcnt > 0 then
    log.dbg("Sending Delete URL: " .. cmdUrl .. "\n")
    local body, err = browser:post_uri(cmdUrl, post)
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
  local nPage = 1
  local nMsgs = 0
  local nTotPages = 0;
  local cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
    internalState.strMBox) .. internalState.strCrumb;
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

      if not uidl or not size then
        log.say("CriticalPath Module needs to fix it's individual message list pattern matching.\n")
        return nil, "Unable to parse the size and uidl from the html"
      end

      -- Convert the size from it's string (4k or 0.86k) to bytes
      --
      size = math.max(tonumber(size), 0) * 1024

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

  -- Local Function to check for more pages of messages.  If found, the 
  -- change the command url
  --
  local function funcCheckForMorePages(body) 
    -- See if there are messages remaining
    --
    if nPage < nTotPages then
      nPage = nPage + 1		
      cmdUrl = baseUrl .. string.format(globals.strCmdMsgListNextPage, nPage)
      return false
    end
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
    local _, _, strSessExpr = string.find(body, globals.strRetLoginSessionExpired)
    if strSessExpr == nil then
      -- Invalidate the session
      --
      internalState.bLoginDone = nil
      session.remove(hash())

      -- Try Logging back in
      --
      local status = login()
      if status ~= POPSERVER_ERR_OK then
        return nil, "Session expired.  Unable to recover"
      end
	
      -- Reset the local variables		
      --
      browser = internalState.browser
      cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
        internalState.strMBox) .. internalState.strCrumb;
      if nPage > 1 then
        cmdUrl = cmdUrl .. string.format(globals.strCmdMsgListNextPage, nPage)
      end

      -- Retry to load the page
      --
      body, err = browser:get_uri(cmdUrl)
    end

    -- Get the total number of messages
    --
    if nTotPages == 0 then
      local _, _, strTotPages = string.find(body, globals.strNumPagesPat)

      if strTotPages ~= nil then
        nTotPages = tonumber(strTotPages)
      else
        nTotPages = 1
      end
      log.dbg("Total Pages in message list: " .. nTotPages)
    end
	
    return body, err
  end


  -- Run through the pages and pull out all the message pieces from
  -- all the message lists
  --
  if not support.do_until(funcGetPage, funcCheckForMorePages, funcProcess) then
    log.error_print("STAT Failed.\n")
    session.remove(hash())
    return POPSERVER_ERR_NETWORK
  end
	
  -- Update our state
  --
  internalState.bStatDone = true
	
  -- Check to see that we completed successfully.  If not, return a network
  -- error.  This is the safest way to let the email client now that there is
  -- a problem but that it shouldn't drop the list of known uidls.
  if (nPage < nTotPages) then
    return POPSERVER_ERR_NETWORK
  end

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
