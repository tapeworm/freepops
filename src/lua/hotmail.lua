-- ************************************************************************** --
--  FreePOPs @hotmail.com webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russells@despammed.com>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.0.7"
PLUGIN_NAME = "hotmail.com"
PLUGIN_REQUIRE_VERSION = "0.0.15"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://freepops.sourceforge.net/download.php?file=hotmail.lua"
PLUGIN_HOMEPAGE = "http://freepops.sourceforge.net/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager"}
PLUGIN_AUTHORS_CONTACTS = {"russells (at) despammed (.) com"}
PLUGIN_DOMAINS = {"@hotmail.com","@hotmail.co.uk","@hotmail.co.jp",
	"@hotmail.de","@msn.com","@webtv.com","@charter.com",
	"@compaq.net","@passport.com"}
PLUGIN_PARAMETERS = {
	{name="folder", description={
		it=[[La cartella che vuoi ispezionare. Quella di default &egrave; Inbox. Gli altri valori possibili sono: Junk, Trash, Draft, Sent.]],
		en=[[The folder you want to interact with. Default is Inbox, other values are: Junk, Trash, Draft, Sent.]]}
	},
	{name = "emptytrash", description = {
		en = [[
Parameter is used to force the plugin to empty the trash when it is done
pulling messages.  Set the value to 1.]]
		}	
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



-- Domains supported:  hotmail.com, msn.com, webtv.com, charter.com, compaq.net,
--                     passport.com

-- TODO
-- 
-- - Support user defined mailboxes.  For now, we support: Inbox, Junk, Sent, Drafts, Trash

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

local globals = {
  -- Server URL
  --
  strLoginUrl = "http://www.hotmail.com/",

  -- Login strings
  -- TODO: Define the HTTPS version
  --
  strLoginPostData = "login=%s&domain=%s&passwd=%s&sec=&mspp_shared=&padding=%s",
  strLoginPaddingFull = "xxxxxxxxxxxxxxxx",
  strLoginFailed = "Login Failed - Invalid User name and/or password",

  -- Expressions to pull out of returned HTML from Hotmail corresponding to a problem
  --
  strRetLoginBadLogin = "(memberservices)",
  strRetLoginSessionExpired = "(Sign in)",
  
  -- Regular expression to extract the mail server
  --
  
  -- Extract the server to post the login data to
  --
  strLoginPostUrlPattern1='name=[%w]+ action="([^"]*)"',
  strLoginPostUrlPattern2='name="([^"]*)" value="([^"]*)"',
  strLoginPostUrlPattern3='<form TARGET="_top" name="%s" action="([^"]*)"',
  strLoginDoneReloadToHMHome='URL=(.*[^"])"',

  -- Get the crumb value that is needed for every command
  --
  strRegExpCrumb = '&a=([^"&]*)[&"]',

  -- Image server pattern
  --
  strImgServerPattern = 'img src="(http://[^/]*)/spacer.gif"',

  -- Pattern to determine if we have no messages
  --
  strMsgListNoMsgPat = "(There are no messages in this folder)",

  -- Used by Stat to pull out the message ID and the size
  --
  strMsgLineLitPattern = ".*<tr>.*<td>[.*]{img}.*</td>.*<td>.*<img>.*</td>.*<td>[.*]{img}.*</td>.*<td>.*<input>.*</td>.*<td>.*</td>.*<td>.*<a>.*</a>.*</td>.*<td>.*</td>.*<td>.*</td>.*<td>.*</td>.*</tr>",
  strMsgLineAbsPattern = "O<O>O<O>[O]{O}O<O>O<O>O<O>O<O>O<O>[O]{O}O<O>O<O>O<X>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O>X<O>O<O>",

  -- Pattern used by Stat to get the next page in the list of messages
  --
  strMsgListNextPagePattern = '(nextpg%.gif" border=0></a>)',

  -- The amount of time that the session should time out at.
  -- This is expressed in seconds
  --
  nSessionTimeout = 28800,  -- 8 hours!

  -- Defined Mailbox names - These define the names to use in the URL for the mailboxes
  --
  strNewFolderPattern = "(curmbox=0)",
  strFolderPrefix = "00000000-0000-0000-0000-000",

  strInbox = "F000000001",
  strJunk =  "F000000005",
  strTrash = "F000000004",
  strDraft = "F000000003",
  strSent =  "F000000002",

  strInboxPat = "([iI]nbox)",
  strJunkPat = "([Jj]unk)",
  strSentPat = "([Ss]ent)",
  strDraftPat = "([Dd]rafts)",
  strTrashPat = "([Tt]rash)",

  -- Command URLS
  --
  strCmdMsgList = "http://%s/cgi-bin/HoTMaiL?a=%s&curmbox=%s",
  strCmdMsgListNextPage = "&page=%d&wo=",
  strCmdDelete = "http://%s/cgi-bin/HoTMaiL",
  strCmdDeletePost = "curmbox=%s&_HMaction=delete&wo=&SMMF=0", -- &<MSGID>=on
  strCmdMsgView = "http://%s/cgi-bin/getmsg?msg=%s&imgsafe=y&curmbox=&s&a=&s",
  strCmdMsgViewRaw = "&raw=0",
  strCmdEmptyTrash = "http://%s/cgi-bin/dofolders?_HMaction=DoEmpty&curmbox=F000000004&a=%s&i=F000000004",
  strCmdLogout = "http://%s/cgi-bin/logout",
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
  strImgServer = nil,
  strDomain = nil,
  strCrumb = nil,
  strMBox = nil,
  bEmptyTrash = false,
  loginTime = nil,
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

-- Issue the command to login to Hotmail
--
function loginHotmail()
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

  -- Retrieve the login page.
  --
  local body, err = browser:get_uri(url)

  -- No connection
  --
  if body == nil then
    log.error_print("Login Failed: Unable to make connection")
    return POPSERVER_ERR_NETWORK
  end

  -- The login page returns a page where a form needs to be asubmitted.  We'll do it
  -- manually.  Extract the form elements and post the data
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
  body, err = browser:post_uri(url, postdata)

  -- Hotmail will return with the login page.  This page supports a slew of domains.
  -- Pull out the place where we need to post the login information.  Post the form
  -- to login.
  --
  local domainWithUnderscore = string.gsub(domain, "%.", "_")
  local pattern = string.format(globals.strLoginPostUrlPattern3, domainWithUnderscore)
  _, _, url = string.find(body, pattern)
  local padding = string.sub(globals.strLoginPaddingFull, 0, 16 - string.len(password))
  postdata = string.format(globals.strLoginPostData, username, domain, password, padding)

  body, err = browser:post_uri(url, postdata)

  -- We should be logged in now!  Unfortunately, we aren't done.  Hotmail returns a page
  -- that should auto-reload in a browser but not in curl.  It's the URL for Hotmail Today.
  --
  _, _, url = string.find(body, globals.strLoginDoneReloadToHMHome)
  if url == nil then
    log.error_print(globals.strLoginFailed)
    return POPSERVER_ERR_AUTH
  end
  
  local _, _, str = string.find(url, globals.strRetLoginBadLogin)
  if str ~= nil then
    log.error_print(globals.strLoginFailed)
    return POPSERVER_ERR_AUTH
  end
  body, err = browser:get_uri(url)

  -- Shouldn't happen but you never know
  --
  if body == nil then
    log.error_print(globals.strLoginFailed)
    return POPSERVER_ERR_AUTH
  end

  -- Save the mail server
  --
  internalState.strMailServer = browser:wherearewe()

  -- DEBUG Message
  --
  log.dbg("Hotmail Server: " .. internalState.strMailServer .. "\n")
  
  -- Extract the crumb - This is needed for deletion of items
  --
  _, _, str = string.find(body, globals.strRegExpCrumb)
  if str == nil then
    log.error_print("Can't get the 'a' value. This will lead to problems!")
    internalState.strCrumb = ""
  else
    internalState.strCrumb = str
  
    -- Debug Message
    -- 
    log.dbg("Hotmail Crumb value: " .. str .. "\n")
  end

  -- Find the image server
  --
  _, _, str = string.find(body, globals.strImgServerPattern)
  if str ~= nil then
    internalState.strImgServer = str
    log.dbg("Hotmail image server: " .. str)
  else
    internalState.strImgServer = internalState.strMailServer
    log.dbg("Couldn't figure out the image server.  Using the mail server as a default.")
  end

  -- See if we are using the new folder id's
  --
  _, _, str = string.find(body, globals.strNewFolderPattern)
  if str ~= nil then
    internalState.strMBox = globals.strFolderPrefix .. 
      string.sub(internalState.strMBox, 2, -1) 
    log.dbg("Hotmail - Using old folder names (" .. internalState.strMBox .. ")")
  end

  -- Note the time when we logged in
  --
  internalState.loginTime = os.clock();

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
    uidl, internalState.strMBox, internalState.strCrumb);
  local markReadUrl = url
  url = url .. globals.strCmdMsgViewRaw

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
    nLinesReceived = 0,

    -- Buffer
    --
    strBuffer = ""
  }
	
  -- Define the callback
  --
  local cb = downloadMsg_cb(cbInfo, data)

  -- Start the download on the body
  -- 
  local f, _ = browser:pipe_uri(url, cb)

  -- Mark the message as read
  --
  browser:get_head(markReadUrl)

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

    -- Update the buffer
    --
    body = cbInfo.strBuffer .. body
    cbInfo.strBuffer = ""
    while (string.len(body) > 4 and string.find(string.sub(body, -4), "(&)") ~= nil) do
      cbInfo.strBuffer = string.sub(body, -4) .. cbInfo.strBuffer
      body = string.sub(body, 1, -5)
    end
  
    -- The only parts we care about are within <pre>..</pre>
    --
    body = string.gsub(body, "<pre>[%s]*", "")
    body = string.gsub(body, "</pre>.*", "")

    -- Clean up the end of line, and replace HTML tags
    --
    body = string.gsub(body, "\n", "\r\n")
    body = string.gsub(body, "&amp;", "&")
    body = string.gsub(body, "&lt;", "<")
    body = string.gsub(body, "&gt;", ">")
    body = string.gsub(body, "&quot;", '"')
    body = string.gsub(body, "<!%-%-%$%$imageserver%-%->", internalState.strImgServer)

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

  -- If the flag emptyTrash is set to 1 ,
  -- the trash will be emptied on 'quit'
  --
  local val = (freepops.MODULE_ARGS or {}).emptytrash or 0
  if val == "1" then
    log.dbg("Hotmail: Trash folder will be emptied on exit.")
    internalState.bEmptyTrash = true
  end

  -- Get the folder
  --
  local mbox = (freepops.MODULE_ARGS or {}).folder
  if mbox == nil then
    internalState.strMBox = globals.strInbox
    return POPSERVER_ERR_OK
  end

  local _, _, start = string.find(mbox, globals.strJunkPat)
  if start ~= nil then
    internalState.strMBox = globals.strJunk
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

  _, _, start = string.find(mbox, globals.strDraftPat)
  if start ~= nil then
    internalState.strMBox = globals.strDraft
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
      return loginHotmail()
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
    return loginHotmail()
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
  local postBase = string.format(globals.strCmdDeletePost, internalState.strMBox)
  local post = postBase

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      post = post .. "&" .. get_mailmessage_uidl(pstate, i) .. "=on"
      dcnt = dcnt + 1

      -- Send out in a batch of 5
      --
      if math.mod(dcnt, 5) == 0 then
        log.dbg("Sending Delete URL: " .. cmdUrl .. "Post Data: " .. post .. "\n")
        local body, err = browser:post_uri(cmdUrl, post)
        if not body or err then
          log.error_print("Unable to delete messages.\n")
        end
       
        -- Reset the variables
        --
        dcnt = 0
        post = postBase
      end
    end
  end

  -- Send whatever is left over
  --
  if dcnt > 0 and dcnt < 5 then
    log.dbg("Sending Delete URL: " .. cmdUrl .. "Post Data: " .. post .. "\n")
    local body, err = browser:post_uri(cmdUrl, post)
    if not body or err then
      log.error_print("Unable to delete messages.\n")
    end
  end

  -- Empty the trash
  --
  if internalState.bEmptyTrash then
    if internalState.strCrumb ~= '' then
      cmdUrl = string.format(globals.strCmdEmptyTrash, internalState.strMailServer,internalState.strCrumb)
      log.dbg("Sending Empty Trash URL: " .. cmdUrl .."\n")
      local body, err = browser:get_uri(cmdUrl)
      if not body or err then
        log.error_print("Error when trying to empty the trash with url: ".. cmdUrl .."\n")
      end
    else
      log.error_print("Cannot empty trash - crumb not found\n")
    end
  end

  -- Should we force a logout.  If this session runs for more than a day, things
  -- stop working
  --
  local currTime = os.clock()
  local diff = currTime - internalState.loginTime
  if diff > globals.nSessionTimeout then 
    cmdUrl = string.format(globals.strCmdLogout, internalState.strMailServer)
    log.dbg("Sending Logout URL: " .. cmdUrl .. "\n")
    local body, err = browser:get_uri(cmdUrl)
 
    log.dbg("Logout forced to keep hotmail session fresh and tasty!  Yum!\n")
    log.dbg("Session removed - Account: " .. internalState.strUser .. 
      "@" .. internalState.strDomain .. "\n")
    session.remove(hash())
    return POPSERVER_ERR_OK
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
  local cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
    internalState.strCrumb, internalState.strMBox);
  local baseUrl = cmdUrl

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
    if (nomesg ~= nil) then
      return true, nil
    end

    -- Tokenize out the message ID and size for each item in the list
    --    
    local items = mlex.match(body, globals.strMsgLineLitPattern, globals.strMsgLineAbsPattern)
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
        log.say("Hotmail Module needs to fix it's individual message list pattern matching.\n")
        return nil, "Unable to parse the size and uidl from the html"
      end

      -- Get the message id.  It's in the format of "MSG[numbers].[number(s)]".
      --
      _, _, uidl = string.find(uidl, 'name="([^"]+)"')

      local bUnique = true
      for j = 0, nMsgs do
        if knownIDs[j + 1] == uidl then
          bUnique = false
          break
        end        
      end

      -- Convert the size from it's string (4KB or 2MB) to bytes
      -- First figure out the unit (KB or just B)
      --
      local _, _, kbUnit = string.find(size, "([Kk])")
      _, _, size = string.find(size, "([%d]+)[KkMm]")
      if not kbUnit then 
        size = math.max(tonumber(size), 0) * 1024 * 1024
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

    -- We are done with this page, increment the counter
    --
    nPage = nPage + 1		
    
    return true, nil
  end 

  -- Local Function to check for more pages of messages.  If found, the 
  -- change the command url
  --
  local function funcCheckForMorePages(body) 
    -- Look in the body and see if there is a link for a next page
    -- If so, change the URL
    --
    local _, _, hasNextPage = string.find(body, globals.strMsgListNextPagePattern)
    if hasNextPage ~= nil then
      cmdUrl = baseUrl .. string.format(globals.strCmdMsgListNextPage, nPage)
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
      local status = loginHotmail()
      if status ~= POPSERVER_ERR_OK then
        return nil, "Session expired.  Unable to recover"
      end
	
      -- Reset the local variables		
      --
      browser = internalState.browser
      cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
        internalState.strCrumb, internalState.strMBox);
      if nPage > 1 then
        cmdUrl = cmdUrl .. string.format(globals.strCmdMsgListNextPage, nPage)
      end

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
