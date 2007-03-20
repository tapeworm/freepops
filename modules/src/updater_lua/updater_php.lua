--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

MODULE_VERSION = "0.0.1"
MODULE_NAME = "updater_php"
MODULE_REQUIRE_VERSION = "0.2.0"
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
local list_URL = base_URL.."listmodules.php?type=%s&fp_version=%s"
local getxml_URL = base_URL.."download.php?xml%s=%s&fp_version=%s"
local getfile_URL = base_URL.."download.php?%s=%s.lua&fp_version=%s"

module("updater_php")

--- 
-- Returns a list of module names that are available upstream.
-- @param kind string official of contrib.
-- @param b browser the browser, a new one is created if nil.
-- @return table the list of modules, or nil plus an error message.
function list_modules(kind,b)
	kind = kind or "official"
	local b = b or browser.new()
	local url = string.format(list_URL,kind,freepops.version())
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
-- @param name string a module name(s) separated by comma.
-- @param kind string official of contrib.
-- @param b browser the browser, a new one is created if nil.
-- @return table with the following fields: version require_version url local_path local_version can_update why_cannot_update should_update. 
function fetch_module_metadata(name,kind,b)
	kind = kind or "official"
	if name == nil then
		return nil, "fetch_module_metadata: No module name(s) given."
	end
	local typ
	if kind == "official" then typ = "module" else typ = "contrib" end
	local b = b or browser.new()
	local names = ""
	for x in string.gmatch(name,"([^,]+)") do
		names = names .. x .. ".xml,"
	end
	-- remove last ','
	names = string.sub(names,1,-2)
	local url = string.format(getxml_URL,typ,names,freepops.version())
	local body, err = b:get_uri(url)
	if not body then return nil, err end

	local txml, err = xml2table.xml2table(body)
	if txml == nil then return nil, err end

	local mdlist = {}
	xml2table.forach_son(txml, "metadata",function(txml)
		local name = txml.name
		-- first son can be either plugin or module
		local version = txml[1].version._content
		local reqversion = txml[1].require_version._content
		local url = txml[1].url._content

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

