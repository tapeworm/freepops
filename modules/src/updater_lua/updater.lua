assert(freepops.loadlib("browser.lua"))()
assert(freepops.loadlib("xml2table.lua"))()
assert(freepops.loadlib("table2xml.lua"))()
assert(freepops.loadlib("plugins2xml.lua"))() 
assert(freepops.loadlib("version_comparer.lua"))() 

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
		local link = txml.url._content
		v[name] = {version = version, 
			require_version = require_version,
			link = link}
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
		v[name] = {version = version, 
			require_version = require_version,
			path = file}
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
	local todo = {}
	
	-- load the todo
	table.foreach(old_versions, function(name,v)
		local avail = versions[name] or {}
		local version = avail.version or ""
		local vc = version_comparer 
		log.dbg("For " .. name .. " " .. v.version .. " >= " .. version)
		local rc = vc.compare_versions(v.version,version)
		if rc == nil then
			log.error_print("Versions uncomparable: " .. 
				v.version .. " " ..  version)
			log.error_print("We try the upgrade!")
			rc = -1
		end
		if rc == -1 then
			-- new version available
			local new = freepops.enough_new(avail.require_version)
			if not new then
				log.say("A new version of " .. name .. 
				"is available, but will not be downladed "..
				"since it needs a newer core, "..
				"at least version "..avail.require_version)
			else
				log.say(name .. " will be upgraded")
				table.insert(todo, {
					name = name, 
					link = avail.link, 
					path = v.path})
			end
		end
	end)

	-- some helpers
	local useragent = {
		"useragent: curl/"..curl.version().. " () FreePOPs/" ..
		 os.getenv("FREEPOPS_VERSION")
	}
	local function check_fd(f, err, what, path)
		if f == nil then
			log.error_print("Unable to " .. what .. " " .. path)
			log.error_print("error: " .. err)
			return true
		end
		return false
	end
	
	-- update
	table.foreach(todo, function(_, v) 
		local f, data = nil, nil
		local backup = v.path .. ".bak"
		local online_data, err = nil, nil
		log.dbg("  Begin upgrade of " .. v.name)
		log.dbg("  Downloading " .. v.link)
		online_data, err = b:get_uri(v.link, useragent)
		if check_fd(online_data, err, "download", v.link)then return end
		log.dbg("  Backup " .. v.path .. " in " .. backup)
		f, err = io.open(v.path,"r")
		if check_fd(f, err, "read", v.path) then return end
		data = f:read("*a")
		f:close()
		f = io.open(backup ,"w")
		if check_fd(f, err, "write", backup) then return end
		f:write(data)
		f:close()
		log.dbg("  Writing new " .. v.path)
		f = io.open(v.path,"w")
		if check_fd(f, err, "write", v.path) then return end
		f:write(online_data)
		f:close()
		log.dbg("End upgrade of " .. v.name)
		log.say(name .. " updated")
	end)
	
	return 0
end

-- eof
