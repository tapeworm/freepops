---
-- XML plugin extraction.
-- This modules extracs and generates XML from the plugins.
--

plugins2xml = {}

--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--


dofile("table2xml.lua")

local env = {}
local proxy_table = env
local proxy_meta = {
	__index = _G,
	__newindex = function(t,k,v)
		if string.sub(k,1,7) == "PLUGIN_" then
		   	env[k] = v
		else
			--print("skipping assignement for ",k)
		end
	end
}
setmetatable(proxy_table,proxy_meta)

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
	{tag_name = "descriptions"},
	{tag_name = "parameters"}
}

local function add_node_content(t,content,field)
	local i = table.foreachi(t,function(i,v)
		if v.tag_name == field then
			return i
		end
	end)
	table.insert(t[i],content)
end

local require_list = 
	{"VERSION","NAME","REQUIRE_VERSION","LICENSE","URL","HOMEPAGE"}

function plugins2xml.sanity_check()
	-- check required
	table.foreachi(require_list,function(_,v)
		if _G["PLUGIN_"..v] == nil then
			error("PLUGIN_" .. v .. " is required")
		end
	end)
	-- author(s)
	assert(	PLUGIN_AUTHORS_NAMES ~= nil and 
		PLUGIN_AUTHORS_CONTACTS ~= nil and
		type(PLUGIN_AUTHORS_NAMES) == "table" and
		type(PLUGIN_AUTHORS_CONTACTS) == "table", 
			"invalid format of PLUGIN_AUTHORS_NAMES or "..
			"PLUGIN_AUTHORS_CONTACTS, must be "..
			"{\"author1\",\"author2\",..} or "..
			"{\"contact1\",\"contact2\",...}")
	local counter = 0
	table.foreachi(PLUGIN_AUTHORS_NAMES,function(i,name)
		local contact = PLUGIN_AUTHORS_CONTACTS[i]
		if contact == nil then
			error("No contact for author "..name)
		end
		counter = counter + 1
	end)
	assert(counter > 0, "At least one author must be provided")
	-- domains
	local counter = 0
	assert(	PLUGIN_DOMAINS ~= nil and type(PLUGIN_DOMAINS == "table"),
		"PLUGIN_DOMAINS is required and must a be a list of strings")
	table.foreachi(PLUGIN_DOMAINS,function(i,name)
		counter = counter + 1
	end)
	assert(counter > 0, "At least one domain must be provided")
	-- desc
	local counter = 0
	assert(	PLUGIN_DESCRIPTIONS ~= nil and 
	 	type(PLUGIN_DESCRIPTIONS == "table"),
		"PLUGIN_DESCRIPTIONS is required and must a be a "..
		"map from lang to strings, like {it=\"bla bla bla\", ".. 
		"en = \"bla bla bla\"}")
	table.foreach(PLUGIN_DESCRIPTIONS,function(lang,name)
		counter = counter + 1
	end)
	assert(counter > 0, "At least one description must be provided")
	-- param
	PLUGIN_PARAMETERS = PLUGIN_PARAMETERS or {}
	assert(	PLUGIN_PARAMETERS ~= nil and 
		type(PLUGIN_PARAMETERS == "table"),
		"PLUGINS_PARAMETERS must a be a list of strings")
	table.foreachi(PLUGIN_PARAMETERS,function(i,p)
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

plugins2xml.extractor_function = function(file)
	dofile(file)
	assert(plugins2xml.sanity_check(),"Sanity checks failed")
	-- add required
	table.foreachi(require_list,function(_,v)
		add_node_content(plugin_Txml,
		{_G["PLUGIN_"..string.upper(v)]},string.lower(v))
	end)
	-- add author(s)
	table.foreachi(PLUGIN_AUTHORS_NAMES,function(i,name)
		local contact = PLUGIN_AUTHORS_CONTACTS[i]
		add_node_content(plugin_Txml,
			{tag_name = "author",
				{tag_name = "name", {name}},
				{tag_name = "contact", {contact}},
			},"authors")
	end)
	-- add domains
	table.foreachi(PLUGIN_DOMAINS,function(i,name)
		add_node_content(plugin_Txml,
			{tag_name = "domain",{name}},"domains")
	end)
	-- add descriptions
	table.foreach(PLUGIN_DESCRIPTIONS,function(lang,name)
		add_node_content(plugin_Txml,
			{tag_name = "description",
			 lang=lang,
			 {name}},"descriptions")
	end)
	-- add parameters
	PLUGIN_PARAMETERS = PLUGIN_PARAMETERS or {}
	table.foreachi(PLUGIN_PARAMETERS,function(i,p)
		local name = p.name
		local description = p.description
		local node = {
			tag_name = "parameter",
			name = name,
			{tag_name = "descriptions"}
		}
		add_node_content(plugin_Txml,node,"parameters")
		table.foreach(description,function(lang,name)
			add_node_content(node,
				{tag_name = "description",
				 lang=lang,
				 {name}},"descriptions")
		end)
	end)

end

local restricted_enviroment = proxy_table
setfenv(extractor_function,restricted_enviroment)


--=======================================================================--

-- this is called with the filename 

plugins2xml.main = function(file)
	plugins2xml.extractor_function(file)
	print(table2xml.table2xml(plugin_Txml))
end

-- since this can be loaded as plugin it must have at least the init function
if init == nil then
	_G.init = function(p) return 0 end
end

-- eof
