--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

--- XXX This modules is unfinished, and probably unneeded XXX ---

MODULE_VERSION = "0.0.1"
MODULE_NAME = "updater_cvs"
MODULE_REQUIRE_VERSION = "0.2.0"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=updater_cvs.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

error("The cvs backend is unfinished, and probably not needed.")

local updater_common = require "updater_common"
local browser = require "browser"
local xml2table = require("xml2table")
local io, os, table, string = io, os, table, string
local freepops,log = freepops,log
local ipairs = ipairs
local print = print

-- ************************************************************************** --
--  Global Strings
-- ************************************************************************** --

-- STAT URL
local strSTATUrl = "http://freepops.cvs.sourceforge.net/freepops/freepops/src/lua/"
-- RETR URL
local strRETRUrl = "http://freepops.cvs.sourceforge.net/*checkout*/freepops/freepops/src/lua/%s?revision=%s"
-- FreePOPs URL
local strFreePOPsURL = "http://www.freepops.org"
-- Plugin pattern
local strPluginPat = 'href="/freepops/freepops/src/lua/([^%?]+)%?revision=([^&]+)&amp;view=markup"'
-- Version Pattern
local strVersionPat = '[PM][LO][UD][GU][IL][NE]_VERSION =[^"]-"([^"]+)"'
local strRequireVersionPat = '[PM][LO][UD][GU][IL][NE]_REQUIRE_VERSION =[^"]-"([^"]+)"'

local function list_modules_aux(browser)
  local cmdUrl = strSTATUrl;

  -- Get the list of plugins
  --
  local body, err = browser:get_uri(cmdUrl)
  if body == nil or err then
    log.error_print("Unable to get list of plugins and version: "..err.."\n")
    return nil, err
  end

  -- Cycle through the plugins
  --
  local rc = {}
  for plugin, ver in string.gmatch(body, globals.strPluginPat) do
	rc[plugin] = ver
  end
  return rc	
end


local function getNewVersion(newLua, plugin) 
  local ver = string.match(newLua, strVersionPat)
  local reqver = string.match(newLua, strRequireVersionPat)

  if (ver == nil) then
    log.error_print("Unable to determine the version of the update to "..
      "plugin: " .. plugin ..  ".  A default version of 0.0.0 will be used.")
      ver = "0.0.0"
  end
  if (reqver == nil) then
    log.error_print("Unable to determine the require version of the update "..
      "to plugin: " .. plugin ..".  A default version of 0.0.0 will be used.") 
    reqver = "0.0.0"
  end

  return ver, reqver
end

module("updater_cvs")

---
-- Downloads the module.
-- -- XXX change the call of this in updaterpop3.lua
-- @param name string the module name.
-- @param substitute boolean true to substitute it, that is putting hte new version somewhere that overrides the original one.
-- @param version string The version to download.
-- @param browser table To reuse a browser.
-- @return string "" if substitute and no errors in writing, nil, err if some error occurred, a huge string if not substitute and no errors.
function fetch_module(name,replace,version,browser) --pstate, msg, data)
  local url = string.format(globals.strRETRUrl, name, version);

  -- Debug Message
  --
  log.dbg("Getting module: " .. name .. ", Version: " .. version)

  -- Get the new name
  --
  local body, err = browser:get_uri(url)
  if (body == nil or err ~= nil) then
    log.error_print("Unable to download the module: " .. name .. 
      " from url: " .. url .. ".  Error returned: " .. err or "<none>") 
    return nil, (err or "<none>")
  end

  if replace == "true" then
    local path = updater_common.update_path_for(name)
    -- XXX check the return code
    updater_common.replace_module(name,body,path) 
    return ""
  else
    return body
  end
end

---
-- Get all infos regarding a module.
-- @param name string a module name.
-- @param browser table To reuse a browser.
-- @return table with the following fields: version require_version url local_path local_version can_update why_cannot_update should_update. 
function fetch_module_metadata(name,browser)
  local browser = browser or browser.new()
  local plugs, err = list_modules_aux(browser)
  if plugs == nil then return nil, err end
  local data, err = fetch_module(name,false,plugs[name],browser)
  if data == nil then return nil, err end
  local newVersion, requiredVersion = getNewVersion(data,name)
  local path = updater_common.update_path_for(name)
  local check_update, should, why_cannot = 
    uc.check_if_updatable(name,reqversion,version,localversion)
  return {
    ["version"]=newVersion,
    ["require_version"]=requiredVersion,
    ["url"]=string.format(strRETRUrl,name,plugs[name]),
    ["local_path"]=path,
    ["local_version"]=updater_common.get_local_version(name),
    ["why_cannot_update"]=why_cannot,
    ["should_update"]=should,
    ["can_update"]=check_update,
  }
end

--- 
-- Returns a list of module names that are available upstream.
-- @param kind string official of contrib.
-- @param browser table To reuse a browser.
-- @return table the list of modules, or nil plus an error message.
function  list_modules(kind,browser)
  local browser = browser or browser.new()
  -- only official are supported by cvs, since unofficial are inside the DB
  --
  if kind ~= "official" then
    log.error_print("Only 'official' plugins are supported by cvs backend")
    return nil, "Only 'official' plugins are supported by cvs backend"
  end

  local plugs, err = list_modules_aux(browser)
  if plugs == nil then return nil, err end
  local rc = {} 
  for pl,_ in pairs(plugs) do
	  rc[#rc+1]=pl
  end
  return rc
end

