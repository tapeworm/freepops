
dofile("modules/include/table2xml.lua")

proxy_table = {}
proxy_meta = {
	__index = _G,
	__newindex = function(t,k,v)
		if string.sub(k,1,7) == "PLUGIN_" then
		   	_G[k] = v
		else
			--print("skipping assignement for ",k)
		end
	end
}
setmetatable(proxy_table,proxy_meta)

plugin_Txml = 
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

function add_node_content(t,content,field)
	local i = table.foreachi(t,function(i,v)
		if v.tag_name == field then
			return i
		end
	end)
	table.insert(t[i],content)
end



require_list = {"VERSION","NAME","REQUIRE_VERSION","LICENSE","URL","HOMEPAGE"}

extractor_function = function(file)
	dofile(file)
	-- check required
	table.foreachi(require_list,function(_,v)
		if _G["PLUGIN_"..v] == nil then
			error("PLUGIN_" .. v .. " is required")
		end
	end)
	-- add required
	table.foreachi(require_list,function(_,v)
		add_node_content(plugin_Txml,
		{_G["PLUGIN_"..string.upper(v)]},string.lower(v))
	end)
	-- add author(s)
	local counter = 0
	assert(	PLUGIN_AUTHORS_NAMES ~= nil and 
		PLUGIN_AUTHORS_CONTACTS ~= nil and
		type(PLUGIN_AUTHORS_NAMES) == "table" and
		type(PLUGIN_AUTHORS_CONTACTS) == "table", 
			"invalid format of PLUGIN_AUTHORS_NAMES or "..
			"PLUGIN_AUTHORS_CONTACTS, must be "..
			"{\"author1\",\"author2\",..} or "..
			"{\"contact1\",\"contact2\",...}")
	table.foreachi(PLUGIN_AUTHORS_NAMES,function(i,name)
		local contact = PLUGIN_AUTHORS_CONTACTS[i]
		if contact == nil then
			error("No contact for author "..name)
		end
		add_node_content(plugin_Txml,
			{tag_name = "author",
				{tag_name = "name", {name}},
				{tag_name = "contact", {contact}},
			},"authors")
		counter = counter + 1
	end)
	assert(counter > 0, "At least one author must be provided")
	-- add domains
	local counter = 0
	assert(	PLUGIN_DOMAINS ~= nil and type(PLUGIN_DOMAINS == "table"),
		"PLUGIN_DOMAINS is required and must a be a list of strings")
	table.foreachi(PLUGIN_DOMAINS,function(i,name)
		add_node_content(plugin_Txml,
			{tag_name = "domain",{name}},"domains")
		counter = counter + 1
	end)
	assert(counter > 0, "At least one domain must be provided")
	-- add descriptions
	local counter = 0
	assert(	PLUGIN_DESCRIPTIONS ~= nil and 
	 	type(PLUGIN_DESCRIPTIONS == "table"),
		"PLUGIN_DESCRIPTIONS is required and must a be a "..
		"map from lang to strings, like {it=\"bla bla bla\", ".. 
		"en = \"bla bla bla\"}")
	table.foreach(PLUGIN_DESCRIPTIONS,function(lang,name)
		add_node_content(plugin_Txml,
			{tag_name = "description",
			 lang=lang,
			 {name}},"descriptions")
		counter = counter + 1
	end)
	assert(counter > 0, "At least one description must be provided")
	-- add parameters
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
		local node = {
			tag_name = "parameter",
			name = name,
			{tag_name = "descriptions"}
		}
		add_node_content(plugin_Txml,node,"parameters")
		local counter = 0
		assert(	description ~= nil and 
	 	type(description == "table"),
		"description is required and must a be a "..
		"map from lang to strings, like {it=\"bla bla bla\", ".. 
		"en = \"bla bla bla\"}")
		table.foreach(description,function(lang,name)
			add_node_content(node,
				{tag_name = "description",
				 lang=lang,
				 {name}},"descriptions")
			counter = counter + 1
		end)
		assert(counter > 0, "At least one description must be provided")
	end)

end

restricted_enviroment = proxy_table
setfenv(extractor_function,restricted_enviroment)


--=======================================================================--

-- this is called with the filename 
main = function(file)
	extractor_function(file)
	print(table2xml.table2xml(plugin_Txml))
end

-- since this is a plugin it must have at least the init function
function init() return 0 end
