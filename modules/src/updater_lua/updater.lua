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
		log.dbg("working on " .. name .. "...\n")
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
		log.dbg("working on " .. name .. "...\n")
		local file = freepops.find(name)
		local txml = plugins2xml.extractor_function(file)
		-- this round trip is necessari to have a Txml with 
		-- metamethods (clever lookup on sons). the Txml built from
		-- plugins2xml.extractor_function is not a real txml (but can
		-- be printed since table2xml doesn't relay on metamethods
		-- (that are only for human beings
		local xml = table2xml.table2xml(txml,nil,nil,false)
		local txml = xml2table.xml2table(xml)
		local version = txml.version._content
		local require_version = txml.require_version._content
		v[name] = {version = version, require_version = require_version}
	end)
	return v
end

function main(plugins)
	-- this should be loaded here (to not redefine main)
	freepops.dofile("browser.lua")
	freepops.dofile("xml2table.lua")
	freepops.dofile("table2xml.lua")
	freepops.dofile("plugins2xml.lua") 
	b = browser.new()
--	b:verbose_mode()
	
	if table.getn(plugins) == 0 then
		plugins = fetchlist("official")
	end
	local versions = get_online_versions(plugins)
	print("Verions available online are:")
	table.foreach(versions, function(name,v)
		print("  " .. name .. " " .. v.version .. 
			" requires FreePOPs " .. v.require_version)
	end)
	local old_versions = get_local_versions(plugins)
	print("Verions available locally are:")
	table.foreach(old_versions, function(name,v)
		print("  " .. name .. " " .. v.version .. 
			" requires FreePOPs " .. v.require_version)
	end)
	
	
	return 0
end
