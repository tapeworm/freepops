-- ************************************************************************** --
--  FreePOPs @mail.com webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russells@despammed.com>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.0.8c"
PLUGIN_NAME = "mail.com"
PLUGIN_REQUIRE_VERSION = "0.0.17"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://freepops.sourceforge.net/download.php?file=mailcom.lua"
PLUGIN_HOMEPAGE = "http://freepops.sourceforge.net/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager"}
PLUGIN_AUTHORS_CONTACTS = 
	{"russells (at) despammed (.) com"}
PLUGIN_DOMAINS = {"@mail.com","@email.com","@iname.com","@cheerful.com","@consultant.com",
"@europe.com","@mindless.com","@earthling.net","@myself.com","@post.com",
"@techie.com","@usa.com","@writeme.com","@2die4.com","@artlover.com",
"@bikerider.com","@catlover.com","@cliffhanger.com","@cutey.com",
"@doglover.com","@gardener.com","@hot-shot.com","@inorbit.com",
"@loveable.com","@mad.scientist.com","@playful.com","@poetic.com",
"@popstar.com","@saintly.com","@seductive.com","@soon.com",
"@whoever.com","@winning.com","@witty.com","@yours.com","@africamail.com",
"@arcticmail.com","@asia.com","@australiamail.com","@europe.com",
"@japan.com","@samerica.com","@usa.com","@berlin.com","@dublin.com",
"@london.com","@madrid.com","@moscowmail.com","@munich.com","@nycmail.com",
"@paris.com","@rome.com","@sanfranmail.com","@singapore.com","@tokyo.com",
"@accountant.com","@adexec.com","@allergist.com","@alumnidirector.com","@archaeologist.com",
"@chemist.com","@clerk.com","@columnist.com","@comic.com","@consultant.com",
"@counsellor.com","@deliveryman.com","@diplomats.com","@doctor.com","@dr.com",
"@engineer.com","@execs.com","@financier.com","@geologist.com","@graphic-designer.com",
"@hairdresser.net","@insurer.com","@journalist.com","@lawyer.com","@legislator.com",
"@lobbyist.com","@minister.com","@musician.org","@optician.com","@pediatrician.com",
"@presidency.com","@priest.com","@programmer.net","@publicist.com","@realtyagent.com",
"@registerednurses.com","@repairman.com","@representative.com","@rescueteam.com",
"@scientist.com","@sociologist.com","@teacher.com","@techie.com","@technologist.com",
"@umpire.com","@02.to","@111.ac","@123post.com","@168city.com","@2friend.com",
"@65.to","@852.to","@86.to","@886.to","@aaronkwok.net","@acmilan-mail.com","@allstarstats.com",
"@amrer.net","@amuro.net","@amuromail.com","@anfieldroad-mail.com","@arigatoo.net","@arsenal-mail.com",
"@barca-mail.com","@baseball-mail.com","@basketball-mail.com","@bayern-munchen.com","@birmingham-mail.com",
"@blackburn-mail.com","@bsdmail.com","@bsdmail.org","@c-palace.com","@celtic-mail.com","@charlton-mail.com",
"@chelsea-mail.com","@china139.com","@chinabyte.com","@chinahot.net","@chinarichholdings.com","@coolmail.ac",
"@coventry-mail.com","@cseek.com","@cutemail.ac","@daydiary.com","@dbzmail.com","@derby-mail.com","@dhsmail.org",
"@dokodemo.ac","@doomo.net","@doramail.com","@e-office.ac","@e-yubin.com","@eracle.com","@eu-mail.net",
"@everton-mail.com","@eyah.com","@ezagenda.com","@fastermail.com","@femail.ac","@fiorentina-mail.com",
"@football-mail.com","@forest-mail.com","@freeid.net","@fulham-mail.com","@gaywiredmail.com","@genkimail.com",
"@gigileung.org","@glay.org","@globalcom.ac","@golf-mail.com","@graffiti.net","@gravity.com.au",
"@hackermail.com","@highbury-mail.com","@hitechweekly.com","@hkis.org","@hkmag.com","@hkomail.com",
"@hockey-mail.com","@hollywood-mail.com","@ii-mail.com","@iname.ru","@inboexes.org","@inboxes.com",
"@inboxes.net","@inboxes.org","@insingapore.com","@intermilan-mail.com","@ipswich-mail.com",
"@isleuthmail.com","@jane.com.tw","@japan1.org","@japanet.ac","@japanmail.com","@jayde.com",
"@jcom.ac","@jedimail.com","@joinme.com","@joyo.com","@jpn1.com","@jpol.net","@jpopmail.com",
"@juve-mail.com","@juventus-mail.com","@juventusmail.net","@kakkoii.net","@kawaiimail.com",
"@kellychen.com","@keromail.com","@kichimail.com","@kitty.cc","@kittymail.com",
"@kittymail.net","@lazio-mail.com","@lazypig.net","@leeds-mail.com","@leicester-mail.com",
"@leonlai.net","@linuxmail.org","@liverpool-mail.com","@luvplanet.net","@mailasia.com","@mailjp.net",
"@mailpanda.com","@mailunion.com","@man-city.com","@manu-mail.com","@marchmail.com",
"@markguide.com","@maxplanet.com","@megacity.com","@middlesbrough-mail.com","@miriamyeung.com","@miriamyeung.com.hk",
"@myoffice.ac","@nctta.org","@netmarketingcentral.com","@nettalk.ac","@newcastle-mail.com","@nihonjin1.com",
"@nihonmail.com","@norikomail.com","@norwich-mail.com","@old-trafford.com","@operamail.com","@otakumail.com",
"@outblaze.net","@outgun.com","@pakistans.com","@pokefan.com","@portugalnet.com","@powerasia.com",
"@qpr-mail.com","@rangers-mail.com","@realmadrid-mail.com","@regards.com","@ronin1.com","@rotoworld.com",
"@samilan.com","@searcheuropemail.com","@sexymail.ac","@sheff-wednesday.com","@slonline.net","@smapxsmap.net",
"@southampton-mail.com","@speedmail.ac","@sports-mail.com","@starmate.com","@sunderland-mail.com","@sunmail.ac",
"@supermail.ac","@supermail.com","@surfmail.ac","@surfy.net","@taiwan.com","@talknet.ac",
"@teddy.cc","@tennis-mail.com","@tottenham-mail.com","@utsukushii.net","@uymail.com","@villa-mail.com",
"@webcity.ca","@webmail.lu","@welcomm.ac","@wenxuecity.net","@westham-mail.com","@wimbledon-mail.com",
"@windrivers.net","@wolves-mail.com","@wongfaye.com","@worldmail.ac","@worldweb.ac","@isleuthmail.com",
"@x-lab.cc","@xy.com.tw","@yankeeman.com","@yyhmail.com", "@verizonmail.com", "@lycos.com" }
PLUGIN_PARAMETERS = {
	{name = "folder", description = {
		en = [[
Parameter is used to select the folder (Inbox is the default)
that you wish to access. The folders that are available are the standard folders, called 
INBOX, Drafts, SENT, and 
Trash. For user defined folders, use their name as the value.]],
		it=[[
Per scegliere la mailbox con cui interagire. Valori accettati: INBOX, Drafts, SENT e Trash. Per le folder create da te usa il loro nome.]]
		}	
	},
	{name = "emptytrash", description = {
		en = [[
Parameter is used to force the plugin to empty the trash when it is done
pulling messages.]],
		it = [[
Metti il parametro a 1 se vuoi che il plugin svuoti il cestino automaticamente]]
		}	
	},
}

PLUGIN_DESCRIPTIONS = {
	en=[[
This is the webmail support for @mail.com and all its other domain mailboxes. 
To use this plugin you have to use your full email address as the user 
name and your real password as the password.]],
	it=[[]
Questo plugin permette di leggere la posta del portale @mail.com e tutti gli
altri domini dello stesso gestore. PEr usare il plugin devi usare il tuo
indirizzo di posta completo come username e la tua normale password 
come password.]]
}

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

local globals = {
  -- Login strings
  -- TODO: Define the HTTPS version
  --
  strLoginPage = "http://%s.%s/scripts/common/proxy.main",
  strLoginPage2 = "http://%s.%s/scripts/common/login.main",
  strLoginPage3 = "http://%s.%s/scripts/lycos/lyproxy.main",
  strLoginPostData = "show_frame=Enter&mail_language=us&action=login&login=%s%%40%s&password=%s&domain=%s&siteselected=normal&",
  strLoginPostData2 = "show_frame=Enter&mail_language=us&action=login&login=%s&password=%s&domain=%s&siteselected=normal&",

  strLoginFailed = "Login Failed - Invalid User name and password",

  -- Expressions to pull out of returned HTML from Yahoo corresponding to a problem
  --
  strRetLoginBadPassword = "(Invalid username/password.)",
  strRetLoginSessionExpired = "(Something here!)",

  -- Regular expression to extract the mail server
  --

  -- Get the mail server for Mail.com
  --
  strRegExpMailServer = '(http://[^/]*)/scripts',
  
  -- Used by Stat to pull out the message ID and the size
  --
  strMsgLineLitPattern = ".*<td>.*<a>[.*]{font}[.*]{b}[.*]{/b}[.*]{/font}.*</a>.*</td>.*<td>[.*]{nobr}[.*]{font}[.*]{/font}[.*]{/nobr}.*</td>.*<td>[.*]{font}.*{/font}[.*]</td>.*</tr>",
  strMsgLineLitPattern2 = ".*<td>.*<a>[.*]{b}[.*]{font}[.*]{/font}[.*]{/b}.*</a>.*</td>.*<td>[.*]{nobr}[.*]{font}[.*]{/font}[.*]{/nobr}.*</td>.*<td>[.*]{font}.*{/font}[.*]</td>.*</tr>",
  strMsgLineAbsPattern = "O<O>O<X>[O]{O}[O]{O}[O]{O}[O]{O}O<O>O<O>O<O>[O]{O}[O]{O}[O]{O}[O]{O}O<O>O<O>[O]{O}X{O}[O]<O>O<O>",

  -- MSGID Pattern
  -- 
  strMsgIDPattern = 'msg_uid=([^&]+)&',

  -- Pattern used by Stat to get the total number of messages
  --
--  strMsgListCntPattern = "Showing [^%d]*[%d]+[^%s]* to [^%d]*[%d]+[^%s]* of [^%d]*([%d]+)",
  strMsgListCntPattern = "(%d+) Message%(s%)",

  -- Defined Mailbox names - These define the names to use in the URL for the mailboxes
  --
  strInbox = "INBOX",

  -- Command URLS
  --
  strCmdOptions = "%s/scripts/mail/options.cgi",
  strCmdOptionsPost = "login=%s:%s&mailh=0&updatepreference=Update&",
  strCmdMsgList = "%s/scripts/mail/mailbox.mail?folder=%s&mview=a&mstart=%d&order=Newest",
  strCmdMsgViewHdr = "%s/scripts/mail/read.mail?folder=%s&pbox=0&msg_uid=%s&mprev=&mnext=",
  strCmdMsgView = "%s/getattach/?folder=%s&msg_uid=%s&filename=foo&partsno=0",
  strCmdDelete = "%s/scripts/mail/mailbox.mail", 
  strCmdDeletePost = "folder=%s&order=Oldest&changeview=0&mview=a&mstart=1&delete_selected=yes&move_selected=&flag_selected=&flags=&views=a&folder_name=&selectAllBox=off&matchfield=fr&mpat=&",
  strCmdEmptyTrash = "%s/scripts/mail/Outblaze.mail?emptytrash=1&current_folder=Trash",
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
  bEmptyTrash = false,
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
  local browser = internalState.browser
  local url = "";
  local post = string.format(globals.strLoginPostData, username, domain, password, domain)

  if (domain == "email.com") then
    url = string.format(globals.strLoginPage, "www", "mail.com")
  elseif (domain == "usa.com") then
    url = string.format(globals.strLoginPage, "mail", "usa.com")
  elseif (domain == "lycos.com") then
    url = string.format(globals.strLoginPage3, "mail", "lycos.com")
  elseif (domain == "otakumail.com") then
    post = string.format(globals.strLoginPostData2, username, password, domain)
    url = string.format(globals.strLoginPage2, "www", "otakumail.com")
  else
    url = string.format(globals.strLoginPage, "www", domain)
  end
	
  -- DEBUG - Set the browser in verbose mode
  --
  -- browser:verbose_mode()

  -- Login
  --
  local body, err = browser:post_uri(url, post)

  -- Error checking
  --

  -- No connection
  --
  if body == nil then
    url = string.format(globals.strLoginPage, "www", "mail.com")
    body, err = browser:post_uri(url, post)
    if body == nil then
      log.error_print("Login Failed: Unable to make connection")
      return POPSERVER_ERR_NETWORK
    end
  end

  -- Check for invalid login/password
  -- 
  local _, _, str = string.find(body, globals.strRetLoginBadPassword)
  if str ~= nil then
    log.error_print("Login Failed: Invalid username/Password")
    return POPSERVER_ERR_AUTH
  end

  -- Extract the mail server
  --
  _, _, str = string.find(body, globals.strRegExpMailServer)
  if str == nil then
    log.error_print("Login Failed: Unable to detect mail server")
    return POPSERVER_ERR_UNKNOWN
  else
    internalState.strMailServer = str

    -- DEBUG Message
    --
    log.dbg("Mail.com Mail Server: " .. str .. "\n")
  end
  
  -- Note that we have logged in successfully
  --
  internalState.bLoginDone = true

  -- We need to turn on the option for full headers
  -- 
  url = string.format(globals.strCmdOptions, internalState.strMailServer)
  post = string.format(globals.strCmdOptionsPost, username, domain)
  body, err = browser:post_uri(url, post) -- Ignore the results
	
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
  local hdrUrl = string.format(globals.strCmdMsgViewHdr, internalState.strMailServer,
    internalState.strMBox, uidl);
  local bodyUrl = string.format(globals.strCmdMsgView, internalState.strMailServer,
    internalState.strMBox, uidl);

  -- Get the header
  --
  local headers, _ = getPage(browser, hdrUrl) --browser:get_uri(hdrUrl)
  headers = cleanupHeaders(headers)
  if (headers == nil) then
    return POPSERVER_ERR_UNKNOWN
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

  -- Just send an extra carriage return
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
  
    -- Clean up the end of line
    --
    body = string.gsub(body, "([^\r])\n", "%1\r\n")

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

function getPage(browser, url)
  local body, err = browser:get_uri(url)
  if string.find(body, "(session is sponsored by)") ~= nil then
    body, err = browser:get_uri(url)
  end
  return body, err  
end

function cleanupHeaders(headers)
  -- Cleanup the headers.  They are formatted in HTML.  Remove all the tags
  -- and replace escaped tags
  --
  local origHeaders = headers
  if (internalState.strDomain == "otakumail.com") then
    _, _, headers = string.find(headers, "(From:.-)</font></td></tr>")
  else
    _, _, headers = string.find(headers, '(From:.-)ml_header')
  end
  if (headers == nil) then
    log.dbg("Unable to parse out message body headers!")
    return nil
  end  

  headers = string.gsub(headers, "<!%-%-.-%-%->", "")
  headers = string.gsub(headers, "<!%-%-.*$", "")
  headers = string.gsub(headers, "\n", "")
  headers = string.gsub(headers, "\t", "")
  headers = string.gsub(headers, "<[Ss][Ee][Ll][Ee][Cc][Tt][^>]+>(.-)</[Ss][Ee][Ll][Ee][Cc][Tt]>", "")
  headers = string.gsub(headers, "<script[^>]+>(.-)</script>", "")
  headers = string.gsub(headers, "</td></tr>", "\n")
  headers = string.gsub(headers, "<[bB][Rr]>", "\n")
  headers = string.gsub(headers, "<[bB][Rr] />", "\n")
  headers = string.gsub(headers, "<[^>]+>", "")
  headers = string.gsub(headers, "&#34;", '"')
  headers = string.gsub(headers, "&gt;", ">")
  headers = string.gsub(headers, "&lt;", "<")
  headers = string.gsub(headers, "&nbsp;", " ")
  headers = string.gsub(headers, "From:", "From: ")
  headers = string.gsub(headers, "To:", "To: ")
  headers = string.gsub(headers, "CC:", "CC: ")
  headers = string.gsub(headers, ";[bB]oundary=", ";\n          boundary=")
  
  -- This part could use some cleanup.  There are usually some links in the 
  -- same line as the From:  line. 
  --
  headers = string.gsub(headers, "%[Save address | Block sender%]", "\n")  
  headers = string.gsub(headers, "%[Save Address%]%[Block Sender%]", "\n")  
  headers = string.gsub(headers, "Save Address Block Sender ", "\n")  
  headers = string.gsub(headers, "%[This Is Spam%]\n", "")
  headers = string.gsub(headers, "This Is Spam", "")
  headers = string.gsub(headers, "Previous | Next", "")  
  headers = string.gsub(headers, "\n\n", "\n")

  -- Add some headers
  --
  headers = string.gsub(headers, "%s+$", "\n")
  headers = headers .. "X-FreePOPs-Domain: " .. internalState.strDomain .. "\n";
  headers = headers .. "X-FreePOPs-Folder: " .. internalState.strMBox .. "\n";

  headers = headers .. "\n\n";
  return headers;
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
  local mbox = (freepops.MODULE_ARGS or {}).folder or globals.strInbox  
  internalState.strMBox = mbox

  -- Should the trash be emptied at the end of the session?
  --
  local val = (freepops.MODULE_ARGS or {}).emptytrash or 0
  if val == "1" then
    log.dbg("Mail.com: The trash will be emptied on quit.")
    internalState.bEmptyTrash = true
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
  local postdata = string.format(globals.strCmdDeletePost, internalState.strMBox)
  local cnt = get_popstate_nummesg(pstate)
  local dcnt = 0

  -- Cycle through the messages and see if we need to delete any of them
  -- 
  for i = 1, cnt do
    if get_mailmessage_flag(pstate, i, MAILMESSAGE_DELETE) then
      postdata = postdata .. "sel_" .. get_mailmessage_uidl(pstate, i) .. "=ON&"
      dcnt = dcnt + 1
    end
  end

  -- Send them
  --
  if dcnt > 0 then
    log.dbg("Sending Delete URL: " .. cmdUrl .. "\n")
    local body, err = browser:post_uri(cmdUrl, postdata)
    if not body or err then
      log.error_print("Unable to delete messages.\n")
    end
  end

  -- Empty the trash
  --
  if internalState.bEmptyTrash == true then
    cmdUrl = string.format(globals.strCmdEmptyTrash, internalState.strMailServer)
    log.dbg("Emptying the trash with URL: " .. cmdUrl .. "\n")
    local body, err = browser:get_uri(cmdUrl)
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
  local nTotMsgs = 0;
  local cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
    internalState.strMBox, nMsgs + 1);

  -- Debug Message
  --
  log.dbg("Stat URL: " .. cmdUrl .. "\n");
		
  -- Initialize our state
  --
  set_popstate_nummesg(pstate, nMsgs)

  -- Local function to process the list of messages, getting id's and sizes
  --
  local function funcProcess(body)
    -- Remove commented out html.  It just causes too much trouble.
    --
    body = string.gsub(body, "<!%-%-(.-)%-%->", "") 
    
    -- Tokenize out the message ID and size for each item in the list
    --    
    local strLitPattern = globals.strMsgLineLitPattern
    if (internalState.strDomain == "otakumail.com") then
      strLitPattern = globals.strMsgLineLitPattern2
    end
    local items = mlex.match(body, strLitPattern, globals.strMsgLineAbsPattern)
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
        log.say("Mail.com Module needs to fix it's individual message list pattern matching.\n")
        return nil, "Unable to parse the size and uidl from the html"
      end

      -- Get the message id.  It's a series of a numbers followed by
      -- an underscore repeated.  .
      --
      _, _, uidl = string.find(uidl, globals.strMsgIDPattern) 
      if (uidl ~= nil) then
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
        nMsgs = nMsgs + 1
        log.dbg("Processed STAT - Msg: " .. nMsgs .. ", UIDL: " .. uidl .. ", Size: " .. size)
        set_popstate_nummesg(pstate, nMsgs)
        set_mailmessage_size(pstate, nMsgs, size)
        set_mailmessage_uidl(pstate, nMsgs, uidl)
      end
    end
		
    return true, nil
  end 

  -- Local Function to check for more pages of messages.  If found, the 
  -- change the command url
  --
  local function funcCheckForMorePages(body) 
    -- See if there are messages remaining
    --
    if nMsgs < nTotMsgs then
      cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
        internalState.strMBox, nMsgs + 1);
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
      local status = login()
      if status ~= POPSERVER_ERR_OK then
        return nil, "Session expired.  Unable to recover"
      end
	
      -- Reset the local variables		
      --
      browser = internalState.browser
      cmdUrl = string.format(globals.strCmdMsgList, internalState.strMailServer,
        internalState.strMBox, nMsgs + 1);

      -- Retry to load the page
      --
      return browser:get_uri(cmdUrl)
    end

    -- Get the total number of messages
    --
    if nTotMsgs == 0 then
      _, _, nTotMsgs = string.find(body, globals.strMsgListCntPattern)
      if nTotMsgs == nil then
        nTotMsgs = 0
      else 
        nTotMsgs = tonumber(nTotMsgs)
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