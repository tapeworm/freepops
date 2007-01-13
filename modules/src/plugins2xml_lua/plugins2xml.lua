---
-- XML plugin extraction.
-- This modules extracs and generates XML from the plugins.
--

MODULE_VERSION = "0.0.1"
MODULE_NAME = "plugins2xml"
MODULE_REQUIRE_VERSION = "0.0.99"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=plugins2xml.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

require("table2xml")
require("xml2table")

local private = {}

local require_list = 
	{"VERSION","NAME","REQUIRE_VERSION","LICENSE","URL","HOMEPAGE"}

function private.sanity_check(G)
	-- check required
	local is_a_module = nil
	table.foreachi(require_list,function(_,v)
		if G["PLUGIN_"..v] == nil and G["MODULE_"..v] == nil then
			if is_a_module == true then
				error("MODULE_" .. v .. " is required")
			elseif is_a_module == false then
				error("PLUGIN_" .. v .. " is required")
			else
				error("PLUGIN_"..v.." or MODULE_"..v..
					" is required")
			end
		end
		if (is_a_module == true and G["PLUGIN_"..v] ~= nil) or
		   (is_a_module == false and G["MODULE_"..v] ~= nil) then
			error("only MODULE_* or PLUGIN_*, not both")
		elseif is_a_module == nil then
			is_a_module = G["MODULE_"..v] ~= nil
		end

	end)
	if is_a_module then 
		local f = function(s) 
			return "Field "..s.." not allowed in module" 
		end
		assert(G.MODULE_AUTHORS_NAMES == nil,f("MODULE_AUTHORS_NAMES"))
		assert(G.MODULE_AUTHORS_CONTACTS==nil,f("MODULE_AUTHORS_CONTACTS"))
		assert(G.MODULE_DOMAINS == nil,f("MODULE_DOMAINS"))
		assert(G.MODULE_REGEXES == nil,f("MODULE_REGEXES"))
		assert(G.MODULE_DESCRIPTIONS == nil,f("MODULE_DESCRIPTIONS"))
		assert(G.MODULE_PARAMETERS == nil,f("MODULE_PARAMETERS"))
		assert(G.PLUGIN_AUTHORS_NAMES == nil,f("PLUGIN_AUTHORS_NAMES"))
		assert(G.PLUGIN_AUTHORS_CONTACTS==nil,f("PLUGIN_AUTHORS_CONTACTS"))
		assert(G.PLUGIN_DOMAINS == nil,f("PLUGIN_DOMAINS"))
		assert(G.PLUGIN_REGEXES == nil,f("PLUGIN_REGEXES"))
		assert(G.PLUGIN_DESCRIPTIONS == nil,f("PLUGIN_DESCRIPTIONS"))
		assert(G.PLUGIN_PARAMETERS == nil,f("PLUGIN_PARAMETERS"))
		return true 
	end
	-- author(s)
	assert(	G.PLUGIN_AUTHORS_NAMES ~= nil and 
		G.PLUGIN_AUTHORS_CONTACTS ~= nil and
		type(G.PLUGIN_AUTHORS_NAMES) == "table" and
		type(G.PLUGIN_AUTHORS_CONTACTS) == "table", 
			"invalid format of PLUGIN_AUTHORS_NAMES or "..
			"PLUGIN_AUTHORS_CONTACTS, must be "..
			"{\"author1\",\"author2\",...} or "..
			"{\"contact1\",\"contact2\",...}")
	local counter = 0
	table.foreachi(G.PLUGIN_AUTHORS_NAMES,function(i,name)
		local contact = G.PLUGIN_AUTHORS_CONTACTS[i]
		if contact == nil then
			error("No contact for author "..name)
		end
		counter = counter + 1
	end)
	assert(counter > 0, "At least one author must be provided")
	-- domains
	local counter = 0
	assert(	(G.PLUGIN_DOMAINS ~= nil and type(G.PLUGIN_DOMAINS == "table")) or 
	        (G.PLUGIN_REGEXES ~= nil and type(G.PLUGIN_REGEXES == "table")),
		"PLUGIN_DOMAINS or PLUGIN_REGEXES is required and must be "..
		"a list of strings")
	if (G.PLUGIN_DOMAINS ~= nil) then
		table.foreachi(G.PLUGIN_DOMAINS,function(i,name)
			counter = counter + 1
		end)
	end
	if(G.PLUGIN_REGEXES ~= nil) then
		table.foreachi(G.PLUGIN_REGEXES,function(i,name)
			counter = counter + 1
		end)
	end
	assert(counter > 0, "At least one domain or one regex must be provided")
	-- desc
	local counter = 0
	assert(	G.PLUGIN_DESCRIPTIONS ~= nil and 
	 	type(G.PLUGIN_DESCRIPTIONS == "table"),
		"PLUGIN_DESCRIPTIONS is required and must a be a "..
		"map from lang to strings, like {it=\"bla bla bla\", ".. 
		"en = \"bla bla bla\"}")
	table.foreach(G.PLUGIN_DESCRIPTIONS,function(lang,name)
		counter = counter + 1
	end)
	assert(counter > 0, "At least one description must be provided")
	-- param
	G.PLUGIN_PARAMETERS = G.PLUGIN_PARAMETERS or {}
	assert(	G.PLUGIN_PARAMETERS ~= nil and 
		type(G.PLUGIN_PARAMETERS == "table"),
		"PLUGINS_PARAMETERS must a be a list of strings")
	table.foreachi(G.PLUGIN_PARAMETERS,function(i,p)
		local name = p.name
		local description = p.description
		assert(name ~= nil and description ~= nil and 
			type(name) == "string" and type(description == table),
			"Wrong parameters description")
		local counter = 0
		assert(	description ~= nil and 
	 		type(description == "table"),
			"description is required and must a be a "..
			"map from lang to strings, like {it=\"bla bla bla\", "..
			"en = \"bla bla bla\"}")
		table.foreach(description,function(lang,name)
			counter = counter + 1
		end)
		assert(counter > 0, "At least one description must be provided")
	end)
	return true
end

private.extractor_function = function(file)
	local plugin_Txml = 
	{tag_name = "plugin",
		{tag_name = "name"},
		{tag_name = "version"},
		{tag_name = "require_version"},
		{tag_name = "license"},
		{tag_name = "url"},
		{tag_name = "homepage"},
		{tag_name = "authors"},
		{tag_name = "domains"},
		{tag_name = "regexes"},
		{tag_name = "descriptions"},
		{tag_name = "parameters"}
	}
	local module_Txml = 
	{tag_name = "module",
		{tag_name = "name"},
		{tag_name = "version"},
		{tag_name = "require_version"},
		{tag_name = "license"},
		{tag_name = "url"},
		{tag_name = "homepage"},
	}
	local function add_node_content(t,content,field)
		local i = table.foreachi(t,function(i,v)
			if v.tag_name == field then
				return i
			end
		end)
		table.insert(t[i],content)
	end
	local file = assert(freepops.find(file),"Unable to find "..file)
	local f, err = loadfile(file)
	local G
	G = {
		-- fake environment to just set global variables
		require = function() end,
		module = function() end,
	}
	if f ~= nil then
		setfenv(f,G)
		pcall(f)
	else
		error(err)
	end
	assert(private.sanity_check(G),"Sanity checks failed")
	-- add required
	local prefix = nil
	local xml = nil
	if G["PLUGIN_NAME"] == nil then 
		prefix = "MODULE_" 
		xml = module_Txml
	else 
		prefix = "PLUGIN_" 
		xml = plugin_Txml
	end

	table.foreachi(require_list,function(_,v)
		add_node_content(xml,
		{G[prefix..string.upper(v)]},string.lower(v))
	end)
	-- add author(s)
	G.PLUGIN_AUTHORS_NAMES = G.PLUGIN_AUTHORS_NAMES or {}
	table.foreachi(G.PLUGIN_AUTHORS_NAMES,function(i,name)
		local contact = G.PLUGIN_AUTHORS_CONTACTS[i]
		add_node_content(xml,
			{tag_name = "author",
				{tag_name = "name", {name}},
				{tag_name = "contact", {contact}},
			},"authors")
	end)
	-- add domains
	if(G.PLUGIN_DOMAINS~=nil) then
		table.foreachi(G.PLUGIN_DOMAINS,function(i,name)
			add_node_content(xml,
				{tag_name = "domain",{name}},"domains")
		end)
	end
	-- add domains(regex)
	if (G.PLUGIN_REGEXES ~= nil) then
		table.foreachi(G.PLUGIN_REGEXES,function(i,name)
			add_node_content(xml,
				{tag_name = "regex",{name}},"regexes")
		end)
	end
	-- add descriptions
	G.PLUGIN_DESCRIPTIONS = G.PLUGIN_DESCRIPTIONS or {}
	table.foreach(G.PLUGIN_DESCRIPTIONS,function(lang,name)
		add_node_content(xml,
			{tag_name = "description",
			 lang=lang,
			 {name}},"descriptions")
	end)
	-- add parameters
	G.PLUGIN_PARAMETERS = G.PLUGIN_PARAMETERS or {}
	table.foreachi(G.PLUGIN_PARAMETERS,function(i,p)
		local name = p.name
		local description = p.description
		local node = {
			tag_name = "parameter",
			name = name,
			{tag_name = "descriptions"}
		}
		add_node_content(xml,node,"parameters")
		table.foreach(description,function(lang,name)
			add_node_content(node,
				{tag_name = "description",
				 lang=lang,
				 {name}},"descriptions")
		end)
	end)
	return xml
end



--=======================================================================--

-- this is called with the filename 

plugins2xml = {}

function plugins2xml.extract(file)
	local txml = private.extractor_function(file)
	local xml = table2xml.table2xml(txml,nil,nil,false)
	local Txml = xml2table.xml2table(xml)
	return Txml
end

function main(files) 
	table.foreach(files,function(_,file) 
		local txml = plugins2xml.extract(file)
		print(table2xml.table2xml(txml,nil,nil,false))
	end)
	return 0
end

return plugins2xml

-- eof
