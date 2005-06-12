assert(freepops.loadlib("browser.lua"))()
assert(freepops.loadlib("xml2table.lua"))()
assert(freepops.loadlib("table2xml.lua"))()
assert(freepops.loadlib("plugins2xml.lua"))() 

b = nil
FP = "http://www.freepops.org/"

function fetchlist(kind)
	local file, err = b:get_uri(FP .. "listplugins.php?type=".. kind)
	if file == nil then
		error(err)
	end
	local t = {}
	for l in string.gfind(file,"(.-)%.xml\n") do
		table.insert(t,l)
	end
	return t
end

function download_xml(plugin)
	local file, err = b:get_uri(FP .. "download.php?xml=" .. plugin)
	if file == nil then
		error(err)
	end
	return file
end

function get_online_versions(plugins)
	local v = {}
	table.foreach(plugins,function(_,name)
		local xml = download_xml(name)
		local txml = xml2table.xml2table(xml)
		local version = txml.version._content
		local require_version = txml.require_version._content
		v[name] = {version = version, require_version = require_version}
	end)
	return v
end

function get_local_versions(plugins)
	local v = {}
	table.foreach(plugins,function(_,name)
		local file = freepops.find(name)
		local txml = plugins2xml.extract(file)
		local version = txml.version._content
		local require_version = txml.require_version._content
		v[name] = {version = version, require_version = require_version}
	end)
	return v
end

function main(plugins)
	b = browser.new()
--	b:verbose_mode()
	
	if table.getn(plugins) == 0 then
		plugins = fetchlist("official")
	end
	local versions = get_online_versions(plugins)
	local old_versions = get_local_versions(plugins)
	
	table.foreach(old_versions, function(name,v)
		local avail = versions[name] or {}
		local version = avail.version or ""
		log.dbg("For " .. name .. " " .. v.version .. " >= " .. version)
		if not freepops.is_version_ge(v.version, version) then
			-- new version available
			local new = freepops.enough_new(avail.require_version)
			if not new then
				print(name, "is upgradable (new core needed)")
			else
				print(name, "is upgradable")
			end
		end
	end)
	
	return 0
end
