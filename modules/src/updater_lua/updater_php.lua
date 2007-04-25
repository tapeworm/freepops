--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

MODULE_VERSION = "0.0.1"
MODULE_NAME = "updater_php"
MODULE_REQUIRE_VERSION = "0.2.3"
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

local base_URL = "http://www.freepops.org/"
local getxml_URL = base_URL.."modules.php?type=%s&fp_version=%s"
local getfile_URL = base_URL.."download.php?%s=%s.lua&fp_version=%s"

module("updater_php")

---
-- Get all infos regarding a module.
-- @param kind string official of contrib.
-- @param b browser the browser, a new one is created if nil.
-- @return table with the following fields: version require_version url local_path local_version can_update why_cannot_update should_update. 
function fetch_modules_metadata(kind,b)
	kind = kind or "official"
	local file_typ
	if kind == "official" then
		file_typ = 'module' 
	else 
		file_typ = 'contrib' 
	end
	local fp_version = freepops.version()
	local b = b or browser.new()
	local url = string.format(getxml_URL,kind,fp_version)
	local body, err = b:get_uri(url)
	if not body then return nil, err end

	local txml, err = xml2table.xml2table(body)
	if txml == nil then return nil, err end

	local mdlist = {}
	xml2table.forach_son(txml, "module",function(txml)
		local name = txml._content
		local version = txml['version']
		local reqversion = txml['require_version']
		local url = string.format(getfile_URL,file_typ,name,fp_version)

		local localversion, path = uc.get_local_version(name)

		local file = uc.update_path_for(name)
		local check_update, should, why_cannot = 
		  uc.check_if_updatable(name,reqversion,version,localversion)

		table.insert(mdlist, {
		  ["module_name"]=name,
		  ["version"]=version,
		  ["require_version"]=reqversion,
		  ["url"]=url,
		  ["local_path"]=file,
		  ["local_path_old"]=path or "",
		  ["local_version"]=localversion,
		  ["why_cannot_update"]=why_cannot,
		  ["should_update"]=should,
		  ["can_update"]=check_update,
		})
	end)

	return mdlist
end

---
-- Downloads the module.
-- @param name string the module name.
-- @param substitute boolean true to substitute it, that is putting hte new version somewhere that overrides the original one.
-- @param kind string official of contrib.
-- @param b browser the browser, a new one is created if nil.
-- @return string "" if substitute and no errors in writing, nil, err if some error occurred, a huge string if not substitute and no errors.
function fetch_module(name,substitute,kind,b)
	kind = kind or "official"
	local typ
	if kind == "official" then typ = "module" else typ = "contrib" end
	local b = b or browser.new()
	local url = string.format(getfile_URL,typ,name,freepops.version())
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

