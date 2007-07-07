-- ************************************************************************** --
--  FreePOPs @fastmail.com webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russell822@yahoo.com>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.0.2d"
PLUGIN_NAME = "fastmail.com"
PLUGIN_REQUIRE_VERSION = "0.2.0"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://www.freepops.org/download.php?module=fastmail.lua"
PLUGIN_HOMEPAGE = "http://www.freepops.org/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager"}
PLUGIN_AUTHORS_CONTACTS = {"russell822 (at) yahoo (.) com"}
PLUGIN_DOMAINS = { "@123mail.org", "@150mail.com", "@150ml.com", "@16mail.com",
"@2-mail.com", "@4email.net", "@50mail.com", "@airpost.net", "@allmail.net", 
"@bestmail.us", "@cluemail.com", "@elitemail.org", "@emailgroups.net", "@emailplus.org", 
"@emailuser.net", "@eml.cc", "@fastem.com", "@fast-email.com", "@fastemail.us", 
"@fastemailer.com", "@fastest.cc", "@fastimap.com", "@fastmail.cn", "@fastmail.com.au", 
"@fastmail.fm", "@fastmail.us", "@fastmail.co.uk", "@fastmail.to", "@fmail.co.uk", 
"@fast-mail.org", "@fastmailbox.net", "@fastmessaging.com", "@fea.st", "@f-m.fm", 
"@fmailbox.com", "@fmgirl.com", "@fmguy.com", "@ftml.net", "@hailmail.net", 
"@imap.cc", "@imap-mail.com", "@imapmail.org", "@internet-e-mail.com", "@internetemails.net", 
"@internet-mail.org", "@internetmailing.net", "@jetemail.net", "@justemail.net", "@letterboxes.org", 
"@mailandftp.com", "@mailas.com", "@mailbolt.com", "@mailc.net", "@mailcan.com", "@mail-central.com", 
"@mailforce.net", "@mailftp.com", "@mailhaven.com", "@mailingaddress.org", "@mailite.com", 
"@mailmight.com", "@mailnew.com", "@mail-page.com", "@mailsent.net", "@mailservice.ms", 
"@mailup.net", "@mailworks.org", "@ml1.net", "@mm.st", "@myfastmail.com", "@mymacmail.com", 
"@nospammail.net", "@ownmail.net", "@petml.com", "@postinbox.com", "@postpro.net",
"@proinbox.com", "@promessage.com", "@realemail.net", "@reallyfast.biz", "@reallyfast.info", 
"@rushpost.com", "@sent.as", "@sent.at", "@sent.com", "@speedpost.net", "@speedymail.org", 
"@ssl-mail.com", "@swift-mail.com", "@the-fastest.net", "@theinternetemail.com", "@the-quickest.com", 
"@veryfast.biz", "@veryspeedy.net", "@warpmail.net", "@xsmail.com", "@yepmail.net", "@your-mail.com", 
      }
PLUGIN_PARAMETERS = {
	{name="folder", description={
		it=[[La cartella che vuoi ispezionare. Quella di default &egrave; Inbox, gli altri valori possibili sono: Junk, Trash, Draft, Sent.]],
		en=[[The folder you want to interact with. Default is Inbox, other values are: Junk, Trash, Draft, Sent.]]}
	},
	{name = "emptytrash", description = {
		it = [[ Viene usato per forzare il plugin a svuotare il cestino quando ha finito di scaricare i messaggi. Se il valore &egrave; 1 questo comportamento viene attivato.]],
		en = [[
Parameter is used to force the plugin to empty the trash when it is done
pulling messages.  Set the value to 1.]]
		}	
	},

}
PLUGIN_DESCRIPTIONS = {
	it=[[
Questo plugin vi permette di scaricare la posta da mailbox con dominio della famiglia di @fastmail.com. 
Per usare questo plugin dovrete usare il vostro indirizzo email completo come 
nome utente e la vostra vera password come password.]],
	en=[[
This plugin lets you download mail from fastmail. 
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
  strLoginUrl = "http://www.fmailbox.com/",

  -- Login strings
  --
  strLoginPostData = "MLS=LN-*&FLN-UserName=%s&FLN-Password=%s&MSignal_LN-Authenticate*=Login&FLN-ScreenSize=-1",
  strLoginFailed = "Login Failed - Invalid User name and/or password",

  -- Regular expression to extract the mail server
  --
  strFormActionPat = '<form name="[^"]+" action="([^"]+)"',

  -- Regular expression to get the mailbox id, Ust value and the Udm value
  --
  strMBoxIDPat = '<option value="([^"]+)"[^>]->%s</option>',
  strUstPat = "Ust=([^;]+);",
  strUdmPat = "UDm=([^;]+);",

  -- Expressions to pull out of returned HTML from fastmail corresponding to a problem
  --
  strRetLoginBadLogin = "(The user name or password you entered was incorrect.)",

  -- Is the Session Expired
  --
  strRetLoginSessionExpired = "(Resource Usage)",

  -- Pattern to determine if we have no messages
  --
  strMsgListNoMsgPat = "(There are no messages in this folder)",

  -- Pattern to determine the total number of messages
  --
  strMsgListCntPattern = " of ([%d]+)</b>",

  -- Used by Stat to pull out the message ID and the size
  --
  strMsgLineLitPattern = ".*<tr>.*<td>.*<input>.*</td>.*<td>.*{a}[.*]{/a}[.*]</td>.*<td>.*</td>.*<td>.*</td>.*<td>.*</td>.*<td>.*<a>.*</a>.*</td>.*<td><a>.*</a>.*</td>.*</tr>",
  strMsgLineAbsPattern = "O<O>O<O>O<O>O<O>O<O>O{O}[O]{O}[O]<O>O<O>O<O>O<O>X<O>O<O>O<O>O<O>O<O>O<O>O<O>O<O><X>O<O>O<O>O<O>",

  -- Mailboxes
  --
  strInboxPat = "([iI]nbox)",
  strInbox = "Inbox",
  strSentPat = "([Ss]ent)",
  strSent = "Sent Items",
  strDraftPat = "([Dd]rafts)",
  strDraft = "Drafts",
  strTrashPat = "([Tt]rash)",
  strTrash = "Trash",

  -- Command URLS
  --
  strCmdMsgList = "http://%s/mail/?MLS=MB-*;SMB-FT-TP=0;SMB-MF-SF=Date_1;SMB-MF-DI=20;Ust=%s;SMB-CF=%s;UDm=%s;MSignal=MB-GotoCF**%s",
  strCmdMsgListNextPage = "http://%s/mail/?MLS=MB-*;SMB-FT-TP=0;SMB-MF-SF=Date_1;SMB-MF-DI=20;Ust=%s;SMB-CF=%s;UDm=%s;MSignal=MB-MF-SetPage**", -- plus page number, 0 based
  strCmdMsgView = "http://%s/mail/foo.txt?MLS=MR-**%s*;SMB-FT-TP=0;SMB-MF-SF=Date_1;SMR-Part=;SMR-MsgId=%s;SMB-MF-DI=20;Ust=%s;SMR-FM=%s;SMB-CF=%s;UDm=%s;MSignal=MR-RawView*",
  strCmdDelete = "http://%s/mail/?Ust=%s;UDm=%s",
  strCmdDeletePost = "MLS=MB-*&SMB-FT-TP=0&SMB-MF-TP=0&SMB-MF-SF=Date_1&SMB-MF-DI=20&SMB-CF=%s&FMB-MF-2-CKS=2&MFeedbackSignal=MB-MF-UpdateRows*&_charset_=iso-8859-1&FMB-Action=0&MSignal_MB-ApplyAction*=+Do+&FMB-PeopleTo=&FMB-ST=&FMB-FT-IsMove=1&FMB-FT-GotoCF=%s",
  strCmdEmptyTrash = "http://%s/mail/?MLS=MB-*;SMB-FT-TP=0;SMB-MF-SF=Date_1;SMB-MF-DI=20;Ust=%s;SMB-CF=%s;UDm=%s;MSignal=MB-EmptyTrash**%s",
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
  strMBoxID = nil,
  strTrashID = nil,
  strUst = nil,
  strUdm = nil,
  bEmptyTrash = false,
  strStatBodyCache = nil,
}

-- ************************************************************************** --
--  Debugging functions
-- ************************************************************************** --

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

-- Issue the command to login to fastmail
--
function login()
  log.raw("Entering login")

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
    log.raw("Login failed: Can't get the page: " .. url .. ", Error: " .. (err or "none"));
    return POPSERVER_ERR_NETWORK
  end

  -- Find the action link
  -- 
  url = string.match(body, globals.strFormActionPat)
  if (url == nil) then
    log.error_print("Login Failed: Unable to find the url to log into")
    log.raw("Login Failed: Unable to find the url to log into");
    return POPSERVER_ERR_NETWORK
  end
  local postdata = string.format(globals.strLoginPostData, username .. "@" .. domain, password)
  log.dbg("Fastmail - Sending login information to: " .. url)
  body, err = browser:post_uri(url, postdata)

  -- We should be logged in now!
  --
  local str = string.match(body, globals.strRetLoginBadLogin)
  if str ~= nil then
    log.error_print(globals.strLoginFailed)
    log.raw("Login failed: Sent login info to: " .. (url or "none") .. " and got something we weren't expecting(1):\n" .. body);
    return POPSERVER_ERR_AUTH
  end

  -- Save the mail server, and some other things
  --
  internalState.strMailServer = browser:wherearewe()
  if (internalState.strMBox == globals.strInbox) then
    internalState.strStatBodyCache = body
  end

  -- Get the folder ID
  --
  local strPat = string.format(globals.strMBoxIDPat, internalState.strMBox)
  str = string.match(body, strPat)
  if str ~= nil then
    internalState.strMBoxID = str
    log.dbg("Fastmail - Mailbox (" .. internalState.strMBox .. ") ID: " .. str)
  else
    log.error_print("Can't figure out the mailbox id for: " .. internalState.strMBox)
    log.raw("Can't figure out the mailbox id for: " .. internalState.strMBox .. ", body: " .. body)
    return POPSERVER_ERR_UNKNOWN
  end

  -- Get the Trash ID
  --
  if internalState.bEmptyTrash then
    strPat = string.format(globals.strMBoxIDPat, globals.strTrash)
    str = string.match(body, strPat)
    if str ~= nil then
      internalState.strTrashID = str
      log.dbg("Fastmail - Mailbox (" .. globals.strTrash .. ") ID: " .. str)
    else
      log.error_print("Can't figure out the mailbox id for: " .. globals.strTrash)
      log.raw("Can't figure out the mailbox id for: " .. globals.strTrash .. ", body: " .. body)
    end
  end
  
  -- Get the session ID and the udm values
  --
  local url = browser:whathaveweread()
  str = string.match(url, globals.strUstPat)
  if str ~= nil then
    internalState.strUst = str
    log.dbg("Fastmail - Ust value: " .. str)
  else
    log.error_print("Can't figure out the udm value")
    log.raw("Can't figure out the udm value, body: " .. body)
    return POPSERVER_ERR_UNKNOWN
  end

  str = string.match(url, globals.strUdmPat)
  if str ~= nil then
    internalState.strUdm = str
    log.dbg("Fastmail - Udm Value: " .. str)
  else
    log.error_print("Can't figure out the udm value")
    log.raw("Can't figure out the ust value, body: " .. body)
    return POPSERVER_ERR_UNKNOWN
  end

  -- DEBUG Message
  --
  log.dbg("Fastmail - Server: " .. internalState.strMailServer .. "\n")
  
  -- Note that we have logged in successfully
  --
  internalState.bLoginDone = true
	
  -- Debug info
  --
  log.dbg("Created session for " .. 
    internalState.strUser .. "@" .. internalState.strDomain .. "\n")

  -- Return Success
  --
  log.raw("Successful login")
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
    uidl, uidl, internalState.strUst, uidl, internalState.strMBoxID, internalState.strUdm);

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

  -- If the flag emptyTrash is set to 1 ,
  -- the trash will be emptied on 'quit'
  --
  local val = (freepops.MODULE_ARGS or {}).emptytrash or 0
  if val == "1" then
    log.dbg("Fastmail: Trash folder will be emptied on exit.")
    internalState.bEmptyTrash = true
  end

  -- Get the folder
  --
  local mbox = (freepops.MODULE_ARGS or {}).folder
  if mbox == nil then
    internalState.strMBox = globals.strInbox
    return POPSERVER_ERR_OK
  end

  local start = string.match(mbox, globals.strSentPat)
  if start ~= nil then
    internalState.strMBox = globals.strSent
    return POPSERVER_ERR_OK
  end

  start = string.match(mbox, globals.strTrashPat)
  if start ~= nil then
    internalState.strMBox = globals.strTrash
    return POPSERVER_ERR_OK
  end

  start = string.match(mbox, globals.strDraftPat)
  if start ~= nil then
    internalState.strMBox = globals.strDraft
    return POPSERVER_ERR_OK
  end

  -- Defaulting to the inbox
  --
  log.say("Fastmail: Custom folder selected: " .. mbox .. ".\n")
  internalState.strMBox = mbox
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
  local cmdUrl = string.format(globals.strCmdDelete, internalState.strMailServer, internalState.strUst, 
    internalState.strUdm)
  local cnt = get_popstate_nummesg(pstate)
  local dcnt = 0
  local postBase = string.format(globals.strCmdDeletePost, internalState.strMBoxID, internalState.strMBoxID)
  local post = postBase

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      post = post .. "&" .. "FMB-MF-" .. get_mailmessage_uidl(pstate, i) .. "-Sel=on"
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
      cmdUrl = string.format(globals.strCmdEmptyTrash, internalState.strMailServer, internalState.strUst,
        internalState.strMBoxID, internalState.strUdm, internalState.strTrashID)
      log.dbg("Sending Empty Trash URL: " .. cmdUrl .."\n")
      local body, err = browser:get_uri(cmdUrl)
      if not body or err then
        log.error_print("Error when trying to empty the trash with url: ".. cmdUrl .."\n")
      end
    else
      log.error_print("Cannot empty trash - crumb not found\n")
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
  local nTotMsgs = 0;
  local firstUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
    internalState.strUst, internalState.strMBoxID, internalState.strUdm, internalState.strMBoxID);
  local cmdUrl = firstUrl
  local nextUrl = string.format(globals.strCmdMsgListNextPage, internalState.strMailServer,
    internalState.strUst, internalState.strMBoxID, internalState.strUdm, internalState.strMBoxID);

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
      local size = items:get(0, i - 1) 
      local uidl = items:get(1, i - 1)

      if not uidl or not size then
        log.say("Fastmail Module needs to fix it's individual message list pattern matching.\n")
        return nil, "Unable to parse the size and uidl from the html"
      end

      -- Get the message id.  It's in the format of "MSG[numbers].[number(s)]".
      --
      uidl = string.match(uidl, 'MSignal=MR%-%*%*([^"]+)"')

      -- Convert the size from it's string (4KB or 2MB) to bytes
      -- First figure out the unit (KB or just B)
      --
      local kbUnit = string.match(size, "([Kk])")
      size = string.match(size, "([%d]+)[KkMm]")
      if not kbUnit then 
        size = math.max(tonumber(size), 0) * 1024 * 1024
      else
        size = math.max(tonumber(size), 0) * 1024
      end

      -- Save the information
      --
      nMsgs = nMsgs + 1
      log.dbg("Processed STAT - Msg: " .. nMsgs .. ", UIDL: " .. uidl .. ", Size: " .. size)
      set_popstate_nummesg(pstate, nMsgs)
      set_mailmessage_size(pstate, nMsgs, size)
      set_mailmessage_uidl(pstate, nMsgs, uidl)
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
    -- See if there are messages remaining
    --
    if nMsgs < nTotMsgs then
      cmdUrl = firstUrl
      if (nPage > 1) then
        cmdUrl = nextUrl .. (nPage - 1)
      end
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
    local body, err
    if (internalState.strStatBodyCache ~= nil and internalState.strMBox == globals.strInbox) then
      body = internalState.strStatBodyCache
      internalState.strStatBodyCache = nil
    else
      body, err = browser:get_uri(cmdUrl)
      if body == nil then
        return body, err
      end
    end

    -- Is the session expired
    --
    local strSessExpr = string.match(body, globals.strRetLoginSessionExpired)
    if strSessExpr == nil then
      -- Invalidate the session
      --
      internalState.bLoginDone = nil
      session.remove(hash())
      log.raw("Session Expired - Last page loaded: " .. cmdUrl .. ", Body: " .. body)

      -- Try Logging back in
      --
      local status = login()
      if status ~= POPSERVER_ERR_OK then
        return nil, "Session expired.  Unable to recover"
      end
	
      -- Reset the local variables		
      --
      browser = internalState.browser
      cmdUrl = firstUrl
      if nPage > 1 then
        cmdUrl = nextUrl .. (nPage - 1)
      end

      -- Retry to load the page
      --
      browser:get_uri(cmdUrl)
    end

    -- Get the total number of messages
    --
    if nTotMsgs == 0 then
      local strTotMsgs = string.match(body, globals.strMsgListCntPattern)
      if strTotMsgs == nil then
        nTotMsgs = 0
      else 
        nTotMsgs = tonumber(strTotMsgs)
      end
      log.dbg("Total messages in message list: " .. nTotMsgs)
    end
	
    return body, err
  end


  -- Run through the pages and pull out all the message pieces from
  -- all the message lists
  --
  if not support.do_until(funcGetPage, funcCheckForMorePages, funcProcess) then
    log.error_print("STAT Failed.\n")
    session.remove(hash())
    log.raw("Session removed (STAT Failure) - Account: " .. internalState.strUser .. 
      "@" .. internalState.strDomain) 
    return POPSERVER_ERR_NETWORK
  end
	
  -- Update our state
  --
  internalState.bStatDone = true
	
  -- Check to see that we completed successfully.  If not, return a network
  -- error.  This is the safest way to let the email client now that there is
  -- a problem but that it shouldn't drop the list of known uidls.
  if (nMsgs < nTotMsgs) then
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
