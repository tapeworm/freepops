-- ************************************************************************** --
--  FreePOPs plugin-check webmail interface
--  
--  Released under the GNU/GPL license
--  Written by Russell Schwager <russell822@yahoo.com>
-- ************************************************************************** --

-- Globals
--
PLUGIN_VERSION = "0.0.6b"
PLUGIN_NAME = "updater"
PLUGIN_REQUIRE_VERSION = "0.0.97"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://freepops.sourceforge.net/download.php?contrib=updater.lua"
PLUGIN_HOMEPAGE = "http://freepops.sourceforge.net/"
PLUGIN_AUTHORS_NAMES = {"Russell Schwager"}
PLUGIN_AUTHORS_CONTACTS = {"russells (at) despammed (.) com"}
PLUGIN_DOMAINS = {"@freepops.org", "@updater"}
PLUGIN_PARAMETERS = {
}
PLUGIN_DESCRIPTIONS = {
	it=[[ <Insert translation here>]],
	en=[[
This plugin is used to retrieve updated lua modules for freepops. To use this
plugin correctly, you need to set the settings for the account created for this
to 'leave mail on server'.  The first time, you use this account, all the plugins
will be retrieved.  For support, please post a question to
the forum instead of emailing the author(s).]]
}

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

local globals = {
  -- STAT URL
  --
  strSTATUrl = "http://freepops.cvs.sourceforge.net/freepops/freepops/src/lua/",

  -- RETR URL
  --
  strRETRUrl = "http://freepops.cvs.sourceforge.net/*checkout*/freepops/freepops/src/lua/%s?revision=%s",

  -- FreePOPs URL
  --
  strFreePOPsURL = "http://www.freepops.org",

  -- Plugin pattern
  -- 
  strPluginPat = 'href="/freepops/freepops/src/lua/([^%?]+)%?revision=([^&]+)&amp;view=markup"',

  -- Version Pattern
  --
  strVersionPat = 'PLUGIN_VERSION =[^"]-"([^"]+)"',
  strRequireVersionPat = 'PLUGIN_REQUIRE_VERSION =[^"]-"([^"]+)"',
}

-- ************************************************************************** --
--  State - Declare the internal state of the plugin.  It will be serialized and remembered.
-- ************************************************************************** --

internalState = {
  bStatDone = false,
  bLoginDone = false,
  browser = nil,
  bClearCache = false,
  excludedPlugins = {},
}

-- ************************************************************************** --
--  Helper functions
-- ************************************************************************** --

-- Build a mail header date string
--
function makeDate()
  return os.date("%a, %d %b %Y %H:%M:%S")
end

-- Build a mail header
--
function makeHeader(plugin, version)
  return 
    "Message-Id: <" .. plugin .. "~" .. version .. ">\r\n"..
    "To: user-of-freepops@donot-reply.org\r\n" ..
    "Date: ".. makeDate() .. "\r\n" ..
    "Subject: FreePops plugin update - " .. plugin .. ", Version " .. version .. "\r\n" ..
    "From: freepops-plugin-updater@donot-reply.org\r\n"..
    "User-Agent: freepops ".. PLUGIN_NAME .. " plugin ".. PLUGIN_VERSION .."\r\n"
end

-- Build a mail body
--
function makeBody(plugin, version, nStatus)
  local str = "FreePOPs User,\r\n\r\nAn official plugin: " .. plugin .. " (Version: " ..
  version .. ") has been detected.  "
  if (nStatus == 0) then
    str = str .. "It has been installed successfully."
  elseif nStatus == -1 then
    str = str .. "The plugin cannot be installed as a newer version of FreePOPs is required."
  elseif nStatus == -2 then
    str = str .. "The plugin was not installed as it matched what is currently installed.  " ..
      "This is probably your first time running the updater.  This message can be ignored.  It is being " .. 
      "used to build a database of installed plugin versions."
  else
    str = str .. "An unsuccessful attempt was made at installing the file.  Please try again " ..
      "or check out the log for any error messages."
  end

  str = str .. "  If you have any questions, please see " ..
  "the FreePOPs home page at " .. globals.strFreePOPsURL .. "\r\n\r\nThank you for using the program,\r\n\r\n" ..
  "The FreePOPs Team\r\n"

  return str
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
  local _, _, plugin = string.find(uidl, "([^~]+)~") 
  local _, _, version = string.find(uidl, "~(.*)")
  
  local url = string.format(globals.strRETRUrl, plugin,
    version);

  -- Debug Message
  --
  log.dbg("Getting plugin: " .. plugin .. ", Version: " .. version)

  -- Get the new plugin
  --
  local body, err = browser:get_uri(url)
  if (body == nil or err ~= nil) then
    log.error_print("Unable to download the plugin: " .. plugin .. " from url: " .. url .. 
      ".  Error returned: " .. err or "<none>") 
    return POPSERVER_ERR_UNKNOWN
  end
  local newVersionInfo = getNewVersionInfo(body, plugin)
  local oldVersionInfo = getLocalVersionInfo(plugin)
  local nStatus = checkForUpdate(plugin, newVersionInfo, oldVersionInfo)

  -- Replace the plugin
  --
  if (nStatus == 0) then
    nStatus = replacePlugin(plugin, body, oldVersionInfo)
  end

  -- Network error in reading the plugin
  --
  if (nStatus == 1) then
    return POPSERVER_ERR_NETWORK
  end
  
  -- Alert the user
  --
  mimer.pipe_msg(
    makeHeader(plugin, newVersionInfo.version), 
    makeBody(plugin, newVersionInfo.version, nStatus), 
    nil, 
    globals.strFreePOPsURL, 
    nil, browser, 
    function(s)
      popserver_callback(s, data)
    end, {})

  return POPSERVER_ERR_OK
end

-- ************************************************************************** --
--  Pop3 functions that must be defined
-- ************************************************************************** --

-- Create a browser
--
function user(pstate, username, foo)
  -- Create a browser to do the dirty work
  --
  internalState.browser = browser.new()

  -- Note that we have logged in successfully
  --
  internalState.bLoginDone = true

  -- Check to see if we need to clear the cache
  --
  local val = (freepops.MODULE_ARGS or {}).clearcache or 0
  if val == "1" then
    log.dbg("Updater: Clearing cache -- no updates will take place in this operation.")
    internalState.bClearCache = true
  end

  -- Add any excluded plugins
  --
  internalState.excludedPlugins["freepops.lua"] = true

  return POPSERVER_ERR_OK
end

-- Perform login functionality
--
function pass(pstate, password)
  return POPSERVER_ERR_OK
end

-- Quit abruptly
--
function quit(pstate)
  return POPSERVER_ERR_OK
end

-- Update the mailbox status and quit
--
function quit_update(pstate)
  return POPSERVER_ERR_OK
end

-- Stat command - Get the number of messages and their size
--
function stat(pstate)

  -- Have we done this already?  If so, we've saved the results.
  --
  if internalState.bStatDone then
    return POPSERVER_ERR_OK
  end

  -- We end early if we are looking to clear the cache.  By returning a stat
  -- count of zero, the mail client will clear out its cache.
  --
  if internalState.bClearCache == true then
    set_popstate_nummesg(pstate, 0)
    return POPSERVER_ERR_OK
  end

  -- Local variables
  -- 
  local browser = internalState.browser
  local cmdUrl = globals.strSTATUrl;
  local nMsgs = 0

  -- Debug Message
  --
  log.dbg("Upgrader Stat URL: " .. cmdUrl .. "\n");
		
  -- Initialize our state
  --
  set_popstate_nummesg(pstate, nMsgs)

  -- Get the list of plugins
  --
  local body, err = browser:get_uri(cmdUrl)
  if body == nil or err then
    log.error_print("Unable to get list of plugins and version: " .. err .. "\n")
    return POPSERVER_ERR_NETWORK
  end

  -- Cycle through the plugins
  --
  for plugin, ver in string.gfind(body, globals.strPluginPat) do
    local size = 10240  -- Hard coded for 10k
    local uidl = plugin .. "~" .. ver

    if internalState.excludedPlugins[plugin] ~= true then
      -- Save the information
      --
      nMsgs = nMsgs + 1
      log.dbg("Processed Plugin - Filename: " .. plugin .. ", Ver: " .. ver)
      set_popstate_nummesg(pstate, nMsgs)
      set_mailmessage_size(pstate, nMsgs, size)
      set_mailmessage_uidl(pstate, nMsgs, uidl)
    end
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

  -- Browser
  --
  require("browser")
	
  -- MIME Parser/Generator
  --
  require("mimer")

  -- Common module
  --
  require("common")

  -- xml2table module
  --
  require("xml2table")

  -- table2xml module
  --
  require("table2xml")

  -- plugins2xml module
  --
  require("plugins2xml")
	
  -- version comparer module
  --
  require("version_comparer")

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

-- Utility Functions
--

function replacePlugin(plugin, newLua, versionInfo)
  -- Remove any old backups, and then backup the current file.
  --
  if (versionInfo.backupOldFile == true) then
    local backupName = versionInfo.path .. ".bak"
    os.remove(backupName)
    local fptr, err = io.open(versionInfo.path, "r")
    if (fptr ~= nil) then
      fptr:close()
      local status, err = os.rename(versionInfo.path, backupName)
      if (status == nil or err ~= nil) then
        log.error_print("Unable to backup the plugin: " .. plugin .. 
          ".  The plugin will not be updated, Error: " .. (err or "none"))
        return 1
      end
    end
  end

  -- Write the new plugin out.
  --
  local fptr, err = io.open(versionInfo.path, "w")
  if (fptr == nil or err ~= nil) then
    log.error_print("Unable to update the plugin: " .. plugin .. 
      ".  The plugin will not be updated, Error: " .. (err or "none"))
    return 1
  end
  fptr:write(newLua)
  fptr:close()

  log.dbg("Plugin: " .. plugin .. " was successfully updated.")
  return 0
end

function getLocalVersionInfo(plugin)
  local file = freepops.find(plugin)

  -- The plugin isn't installed
  --
  if file == nil then
    local verInfo = {
      version = "0.0.0",
      requireVersion = "0.0.0",
      path = os.getenv("FREEPOPSLUA_PATH") .. plugin,
      backupOldFile = false
    }
    return verInfo
  end
 
  local txml = plugins2xml.extract(file)
  local version = txml.version._content
  local requireVersion = txml.require_version._content

  local verInfo = {
    version = version,
    requireVersion = requireVersion,
    path = file,
    backupOldFile = true
  }

  return verInfo
end

function getNewVersionInfo(newLua, plugin) 
  local _, _, ver = string.find(newLua, globals.strVersionPat)
  local _, _, reqver = string.find(newLua, globals.strRequireVersionPat)

  local verInfo = {
    version = ver,
    requireVersion = reqver,
  }

  if (verInfo.version == nil) then
    log.error_print("Unable to determine the version of the update to plugin: " .. plugin .. 
      ".  A default version of 0.0.0 will be used.")
    verInfo.version = "0.0.0"
  end
  if (verInfo.requireVersion == nil) then
    log.error_print("Unable to determine the require version of the update to plugin: " .. plugin ..
      ".  A default version of 0.0.0 will be used.") 
    verInfo.requireVersion = "0.0.0"
  end

  return verInfo
end

function checkForUpdate(plugin, newvers, oldvers)
  local checker = version_comparer
  log.dbg("Checking versions for plugin: " .. plugin .. ", New: " .. newvers.version .. 
    ", Old: " .. oldvers.version)

  local rc = checker.compare_versions(newvers.version, oldvers.version)

  -- The check failed! We'll just warn an attempt an upgrade
  --
  if (rc == nil) then
    log.dbg("Warning: Unable to compare the versions")
    rc = 1
  end

  -- A new version is available, check the require version
  --
  if (rc == 1) then
    local isFPOk = freepops.enough_new(newvers.requireVersion)
    if not isFPOk then
      log.dbg("Warning: Unable to update the plugin as it requires a newer version of FreePOPS (" .. 
        newvers.requireVersion .. ")")
      return -1
    end
  -- The version is the same.
  --
  elseif (rc == 0) then
    return -2
  end

  return 0
end

-- standalone functions
--

-- Initialize the plugin
--
function saInit() 
  -- Let the log know that we have been found
  --
  saLog(PLUGIN_NAME .. "(" .. PLUGIN_VERSION ..") Started!")

  -- Browser
  --
  require("browser")
	
  -- MIME Parser/Generator
  --
  require("mimer")

  -- Common module
  --
  require("common")

  -- xml2table module
  --
  require("xml2table")

  -- table2xml module
  --
  require("table2xml")

  -- plugins2xml module
  --
  require("plugins2xml")
	
  -- version comparer module
  --
  require("version_comparer")

  -- Import the freepops name space allowing for us to use the status messages
  --
  freepops.export(pop3server)

  -- Run a sanity check
  --
  freepops.set_sanity_checks()

  -- Let the log know that we have initialized ok
  --
  saLog(PLUGIN_NAME .. "(" .. PLUGIN_VERSION ..") initialized (Standalone)!")

end

-- Get the list and try to update the plugins
--
function updateWorker()
  -- Local variables
  -- 
  local browser = internalState.browser
  local cmdUrl = globals.strSTATUrl;
  local nPlugins = 0

  -- Debug Message
  --
  saLog("Upgrader Plugin List URL: " .. cmdUrl);
		
  -- Get the list of plugins
  --
  local body, err = browser:get_uri(cmdUrl)
  if body == nil then
    saLog("Unable to get list of plugins and version: " .. err)
    return POPSERVER_ERR_NETWORK
  end

  -- Cycle through the plugins
  --
  for plugin, ver in string.gfind(body, globals.strPluginPat) do
    local uidl = plugin .. "~" .. ver
    saLog("Found Plugin: " .. plugin .. ", CVS Version: " .. ver)

    if internalState.excludedPlugins[plugin] ~= true then
      -- Try the update
      --
      nPlugins = nPlugins + 1
      downloadPlugin(uidl)
    end
  end

  -- Update our state
  --
  internalState.bStatDone = true
  saLog("Upgrader Processed " .. nPlugins .. " Plugins");

  -- Return that we succeeded
  --
  return POPSERVER_ERR_OK
end

-- Download a single message
--
function downloadPlugin(uidl)
  -- Local Variables
  --
  local browser = internalState.browser
  local _, _, plugin = string.find(uidl, "([^~]+)~") 
  local _, _, version = string.find(uidl, "~(.*)")
  
  local url = string.format(globals.strRETRUrl, plugin,
    version);

  -- Debug Message
  --
  saLog("Getting plugin: " .. plugin .. ", Version: " .. version)

  -- Get the new plugin
  --
  local body, err = browser:get_uri(url)
  if (body == nil or err ~= nil) then
    saLog("Unable to download the plugin: " .. plugin .. " from url: " .. url .. 
      ".  Error returned: " .. err or "<none>") 
    return POPSERVER_ERR_UNKNOWN
  end

  local newVersionInfo = getNewVersionInfo(body, plugin)
  local oldVersionInfo = getLocalVersionInfo(plugin)

  local nStatus = checkForUpdate(plugin, newVersionInfo, oldVersionInfo)
  
  -- Replace the plugin
  --
  if (nStatus == 0) then
    saLog("Needs Update Status: True")
    nStatus = replacePlugin(plugin, body, oldVersionInfo)
  else
    saLog("Needs Update Status: False")
  end
  
  return POPSERVER_ERR_OK
end

function saLog(msg)
  local fptr, err = io.open("log.txt", "a")
  fptr:write(os.date() .. " -> " .. msg .. "\n")
  fptr:close()
end

-- Drive the upgrade process
--
function main(plugins)
  local pstate = {}

  -- Initialize
  --
  saInit()

  -- Initialize the browser
  --
  user(pstate, nil)

  -- Check for new ones
  --
  updateWorker()

  saLog(PLUGIN_NAME .. "(" .. PLUGIN_VERSION ..") Exitting!")

  return 0
end
-- EOF
-- ************************************************************************** --
