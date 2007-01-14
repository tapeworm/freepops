--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

MODULE_VERSION = "0.0.1"
MODULE_NAME = "updater_php"
MODULE_REQUIRE_VERSION = "0.1.00"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=updater_php.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

local uc = require "updater_common"
local browser = require "browser"
local xml2table = require("xml2table")
local io, os, table, string = io, os, table, string
local freepops, log = freepops, log
local ipairs = ipairs
local print = print

local list_URL = "http://www.freepops.org/listmodules.php?type=%s"
local getxml_URL = "http://www.freepops.org/download.php?xml%s=%s.xml"
local getfile_URL = "http://www.freepops.org/download.php?%s=%s.lua"

module("updater_php")

--- 
-- Returns a list of module names that are available upstream.
-- @param kind string official of contrib.
-- @return table the list of modules, or nil plus an error message.
function list_modules(kind,b)
	kind = kind or "official"
	local b = b or browser.new()
	local url = string.format(list_URL,kind)
	local data, err = b:get_uri(url)
	if data == nil then
		log.error_print(err)
		return nil, err
	end
	local rc = {}
	for l in uc.lines(data) do
		rc[#rc+1] = string.gsub(l,".xml$","")
	end
	return rc
end

---
-- Get all infos regarding a module.
-- @param name string a module name.
-- @return table with the following fields: version require_version url local_path local_version can_update why_cannot_update should_update. 
function fetch_module_metadata(name,kind)
	kind = kind or "official"
	local typ
	if kind == "official" then typ = "module" else typ = "contrib" end
	local b = browser.new()
	local url = string.format(getxml_URL,typ,name)
	local body, err = b:get_uri(url)
	if not body then return nil, err end

	local txml, err = xml2table.xml2table(body)
	if txml == nil then return nil, err end
	local version = txml.version._content
	local reqversion = txml.require_version._content
	local url = txml.url._content

	local localversion = uc.get_local_version(name)

	local file = uc.update_path_for(name)
	local check_update, should, why_cannot = 
	  uc.check_if_updatable(name,reqversion,version,localversion)
	return {
	  ["version"]=version,
	  ["require_version"]=reqversion,
	  ["url"]=url,
	  ["local_path"]=file,
	  ["local_version"]=localversion,
	  ["why_cannot_update"]=why_cannot,
	  ["should_update"]=should,
	  ["can_update"]=check_update,
        }
end

---
-- Downloads the module.
-- @param name string the module name.
-- @param substitute boolean true to substitute it, that is putting hte new version somewhere that overrides the original one.
-- @return string "" if substitute and no errors in writing, nil, err if some error occurred, a huge string if not substitute and no errors.
function fetch_module(name,substitute,kind,b)
	kind = kind or "official"
	local typ
	if kind == "official" then typ = "module" else typ = "contrib" end
	local b = b or browser.new()
	local url = string.format(getfile_URL,typ,name)
	local data,err = b:get_uri(url)
	if not data then return nil, "Fetching: "..url.."\n"..err end
	if substitute == "true" then
		local path = uc.update_path_for(name)
		local ok, err = uc.replace_module(name,data,path)
		if ok then return "" else return nil, err end
	else
		return data
	end
end

