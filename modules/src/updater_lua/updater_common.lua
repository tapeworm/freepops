--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

MODULE_VERSION = "0.0.1"
MODULE_NAME = "updater_common"
MODULE_REQUIRE_VERSION = "0.2.0"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=updater_common.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

local browser = require("browser")
local plugins2xml = require("plugins2xml")
local version_comparer = require("version_comparer")
local io, os, table, string = io, os, table, string
local freepops, log = freepops, log
local ipairs = ipairs
local print = print
local tostring = tostring
local assert = assert

module("updater_common")

-- {{{ helpers 

---
-- Gives an iterator over the lines of a given string.
-- @param s string the data to split in lines.
-- @return function.
function lines(s) return string.gmatch(s,"[^\n][^\n]*") end

---
-- Gives the path of the module.
-- Notice that this is not the path where the module is, but where it should 
-- be placed (i.e. /var under unix, LUA_UPDATES/ under win.
-- @param name string the name of the module.
-- @return string The path.
function update_path_for(name)
	local s,_,namespace = freepops.find(name)
	if s == nil then
		log.error_print("Unable to find "..name)
		log.error_print("Assuming it was a toplevel module")
		s = name..".lua"
		namespace=""
	end
	local name = string.match(s,"([^/]*%.lua)$")

	if namespace ~= "" then namespce = "/" .. namespace end 

	return freepops.MODULES_PREFIX[1]..namespace.."/"..name
end

---
-- Gives the can/should/why triple.
-- @param module string the name of the module.
-- @param reqversion string the version of the core required .
-- @param newversion string the new version of the module.
-- @param oldvers string the old version of the modue.
-- @return bool bool string The can,should,why triple.
function check_if_updatable(module, reqversion, newversion, oldvers)
  log.dbg("Checking versions for module: " .. module .. ", "..
  	"New: " .. newversion ..  ", Old: " .. oldvers)

  local rc = version_comparer.compare_versions(newversion, oldvers)

  -- The check failed! We'll just warn an attempt an upgrade
  --
  if (rc == nil) then
    log.dbg("Warning: Unable to compare the versions")
    rc = 1
  end

  log.dbg("compare_versions("..newversion..","..oldvers..") = "..rc)

  -- A new version is available, check the require version
  --
  if (rc == 1) then
    local isFPOk = freepops.enough_new(reqversion)
    if not isFPOk then
      log.dbg("Warning: Unable to update the module as it requires " .. 
         "a newer version of FreePOPS (" .. reqversion .. ")")
      return false, true, "FreePOPs is too old, needs version "..reqversion
    end
  -- The version is the same.
  --
  elseif (rc <= 0) then
    return true, false, "Already at the newest version"
  end

  return true, true, "New version available"
end

---
-- Installs the module.
-- @param module string The name of the module.
-- @param newlua string The boty of the module.
-- @param path string Where to put it.
-- @return bool true if ok, false plus an err message oherwise.
function replace_module(module, newlua, path)
  -- Remove any old backups, and then backup the current file.
  --
  if path ~= nil then
    local backupName = path .. ".bak"
    os.remove(backupName)
    local fptr, err = io.open(path, "r")
    if (fptr ~= nil) then
      fptr:close()
      local status, err = os.rename(path, backupName)
      if (status == nil or err ~= nil) then
        log.error_print("Unable to backup the module: " .. module .. 
          ".  The module will not be updated, Error: " .. (err or "none"))
        return false, ("Unable to backup the module: "..err)
      end
    end
  end

  -- Write the new module out.
  --
  local fptr, err = io.open(path, "w")
  if (fptr == nil or err ~= nil) then
    log.error_print("Unable to update the module: " .. module .. 
      ".  The module will not be updated, Error: " .. (err or "none"))
    return false, ("Unable to update the module: "..err)
  end
  fptr:write(newlua)
  fptr:close()

  log.dbg("Plugin: " .. module .. " was successfully updated.")
  return true
end

---
-- Gives the local version of a moule.
-- @param module string The module name.
-- @return string The version if available, 0.0.0 if not.
function get_local_version(module)
  local file = freepops.find(module)

  -- The module isn't installed
  --
  if file == nil then
    return "0.0.0"
  else
    local txml = plugins2xml.extract(file)
    local version = txml.version._content
    return version
  end
end

-- }}}

-- {{{ documentation/usage and manglers

local operations = {
	"list_modules", 
	"fetch_module_metadata", 
	"fetch_module",
}

local list_modules_doc = [[
parameters: 
	(official|contrib) : The type of module / default official
	browser object: Lua browser object / default create a new one

answer: A list of "module: string(1)" lines]]
local fetch_module_metadata_doc = [[
parameters: 
	string : The name of the module
	(official|contrib) : The type of module / default official
	browser object: Lua browser object / default create a new one

answer: 
	"version: string"
	"require_version: string"
	"url: string"
	"local_path: string"
	"local_version: string" 
	"can_update: (true|false)"
	"why_cannot_update: string"
	"should_update: (true|false)" 
	
local_path is not the path where the module is but where the update should be
placed. In the local_version line the version may be absent if the module is
not present.]]
local fetch_module_doc = [[
parameters:
	string : The name of the module
	(true|false) : Install the module / default print it
	(official|contrib) : The type of module / default official
	browser object: Lua browser object / default create a new one

answer:
	If an error occurred: "error: string"
	If the second parameter was true then nothing.
	If the second parameter was false then the body of the module.]]

local instructions = {
	["list_modules"] =  list_modules_doc,
	["fetch_module_metadata"] = fetch_module_metadata_doc,
	["fetch_module"] = fetch_module_doc,
}

---
-- prints to stderr
function print_err(s) io.stderr:write(s..'\n') end

---
-- Prints to stderr the comand line syntax of updater.
function common_usage(cmd, stuff, errors)
	cmd = cmd or "freepopsd -e updater.lua"
	local err = print_err
	err("")
	err("Arguments specified and accepted: "..(stuff or ""))
	err("Arguments specified and rejected: "..(errors or ""))
	err("")
	err("Usage: "..cmd.." backend operation args...")
	err("")
	err("Backends:")
	err("\tcvs\tNot implemented")
	err("\tphp")
	err("")
	err("Standard operations:")
	for _,op in ipairs(operations) do
		err("")
		err("Operation: "..op)
		err(instructions[op] or "Not documented")
	end
end

---
-- The table of function to print on stdout the result of the functions.
mangler = {
  ["list_modules"] = function(t, err) 
	  if t == nil then print("error: " .. err);return end
	  table.foreach(t,function(_,v) print(v) end) 
  end,
  ["fetch_module_metadata"] = function(t, err)
	  if t == nil then print("error: " .. err);return end
	  print("version: ".. t.version)
	  print("require_version: ".. t.require_version)
	  print("url: ".. t.url)
	  print("local_path: ".. t.local_path)
	  print("local_version: ".. t.local_version)
	  print("why_cannot_update: ".. t.why_cannot_update)
	  print("can_update: ".. tostring(t.can_update))
	  print("should_update: ".. tostring(t.should_update))
  end,
  ["fetch_module"] = function(s,err)
	  if s == nil then print("error: "..err);return end
	  print(s)
  end,
}

-- }}}

