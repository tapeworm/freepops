t = 	{
	-- name is reserved and is the tag name
	name="tag1",
	-- attributes if different from name
	param1="val1'\"&",
	param2="val2",
		-- a son
		{
		name="tag2",
		param1="val1"
		},
		-- another son
		{
		name="tag3",
			{
			-- no name means data
			"BLABLABLA&BLA 5<6 o'rca"
			}
		},
		-- and so on
		{
		name="ciao",
		lang="it"
		},
		{
		name="hello",
		lang="en"
		},
		{
		name="a",
			{
			name="b",
				{
				name="c",
					{"d"}
				}
			},
			{
			name="b1",
				{"c'"}
			}
		}

	}

function escape(s)
	return (string.gsub(s,[[([><"'&])]],function(x)
		if x == ">" then
			return "&gt;"
		elseif x == "<" then
			return "&lt;"
		elseif x == '"' then
			return "&quot;"
		elseif x == "'" then
			return "&apos;"
		elseif x == "&" then
			return "&amp;"
		end
	end))
end
	
function table2xml_aux(t,oc,indent)
	if t == nil then
		return
	end
	local c_p = string.rep(" ",indent)
	local name = t.name
	local data = t[1]
	if type(data) == "table" then
		data = nil
	end
	if name == nil and data == nil then
		print("Each table must contain a \"data\" or a 'name' field")
		return
	end
	if name ~= nil and data ~= nil then
		print("Data and name can't be togheter")
		return
	end
	if data ~= nil then
		oc:write(escape(data))
		return
	else	
		local pt = {}
		table.foreach(t,function(k,v) 
			if k ~= "name" and type(k) ~= "number" then 
				table.insert(pt,' '..k..'="'..escape(v)..'"') 
			end 
		end)
		local noson = true
		table.foreachi(t,function(k,v) 
			if type(v) == "table" then
				noson = false
				return true --stop loop
			end
		end)
		if noson then
			oc:write(c_p.."<"..name..table.concat(pt).." />")
		else
			local no_cp = false
			oc:write(c_p.."<"..name..table.concat(pt)..">")
			table.foreachi(t,function(k,v)
				if no_cp == true then
					print("double data")
					return true
				end
				if type(v) == "table" then
					if v.name == nil then
						no_cp = true
						table2xml_aux(v,oc,0)
					else
						oc:write("\n")
						table2xml_aux(v,oc,indent+2)
					end
				end
			end)
			if no_cp then
				oc:write("</"..name..">")
			else
				oc:write(c_p.."</"..name..">")
			end
		end
		oc:write('\n')
	end
end

function table2xml(t,oc)
	oc:write('<?xml version="1.0" encoding="iso-8859-1" ?>\n\n')
	table2xml_aux(t,oc,0)
end

fake_file = {s=""}
function fake_file.write(self,...)
	self.s = self.s .. (table.concat(arg))
end
function fake_file.print(self)
	print(self.s)
end

table2xml(t,fake_file)


function lpx_cb_factory(t)
return {
	-- Called when the parser recognizes a XML CData string
	CharacterData = function(p,string) end,
	-- Called when the parser recognizes a XML comment string
	Comment = function(p,string) end,
	-- Called when the parser has a string corresponding to any characters
	-- in the document which wouldn't otherwise be handled. Using this
	-- handler has the side effect of turning off expansion of references
	-- to internally defined general entities. Instead these references are
	-- passed to the default handler
	Default = function(p,string) end,
	-- Called when the parser has a string corresponding to any characters
	-- in the document which wouldn't otherwise be handled. Using this
	-- handler doesn't affect expansion of internal entity references
	DefaultExpand = function(p,string) end,
	-- Called when the parser detects the end of a CDATA section
	EndCdataSection = function(p) end,
	-- Called when the parser detects the ending of an XML element with
	-- elementName
	EndElement = function(p, elementName) end,
	-- Called when the parser detects the ending of a XML namespace with
	-- namespaceName. The handling of the end namespace is done after the
	-- handling of the end tag for the element the namespace is associated
	-- with
	EndNamespaceDecl = function(p, namespaceName) end,
	-- Called when the parser detects an external entity reference.
	-- The subparser is a LuaExpat parser created with the same callbacks
	-- and Expat context as the parser and should be used to parse the
	-- external entity.
	-- The base parameter is the base to use for relative system
	-- identifiers. It is set by parser:setbase and may be nil.
	-- The systemId parameter is the system identifier specified in the
	-- entity declaration and is never nil.
	-- The publicId parameter is the public id given in the entity
	-- declaration and may be nil
	ExternalEntityRef= function(p, sp, base, systemId, publicId) end,
	-- Called when the parser detects that the document is not
	-- "standalone". This happens when there is an external subset or a
	-- reference to a parameter entity, but does not have standalone set to
	-- "yes" in an XML declaration
	NotStandalone= function(p) end,
	-- Called when the parser detects XML notation declarations with
	-- notationName
	-- The base parameter is the base to use for relative system
	-- identifiers. It is set by parser:setbase and may be nil.
	-- The systemId parameter is the system identifier specified in the
	-- entity declaration and is never nil.
	-- The publicId parameter is the public id given in the entity
	-- declaration and may be nil
	NotationDecl= function(p, notationName, base, systemId, publicId)end,
	-- Called when the parser detects XML processing instructions. The
	-- target is the first word in the processing instruction. The data is
	-- the rest of the characters in it after skipping all whitespace after
	-- the initial word
	ProcessingInstruction= function(p, target, data)end,
	-- Called when the parser detects the begining of a XML CDATA section
	StartCdataSection= function(p)end,
	-- Called when the parser detects the begining of a XML element with
	-- elementName. The attributes parameter is a Lua table with all the
	-- element attribute names and values. The table contains an entry for
	-- every attribute in the element start tag and entries for the default
	-- attributes for that element. The attributes are listed by name
	-- (including the inherited ones) and by position (inherited attributes
	-- are not considered in the position list). As an example if the book
	-- element has attributes author, title and an optional format
	-- attribute (with "printed" as default value),
	-- <book author="Ierusalimschy, Roberto" title="Programming in Lua">
        -- would be represented as
	-- {[1] = "Ierusalimschy, Roberto",
        --  [2] = "Programming in Lua",
        --  author = "Ierusalimschy, Roberto",
        --  format = "printed",
        --  title = "Programming in Lua"}
        StartElement= function(p, elementName, attributes)end,
	-- Called when the parser detects a XML namespace declaration with
	-- namespaceName. Namespace declarations occur inside start tags, but
	-- the StartNamespaceDecl handler is called before the StartElement
	-- handler for each namespace declared in that start tag
	StartNamespaceDecl= function(p, namespaceName)end,
	-- Called when the parser receives declarations of unparsed entities.
	-- These are entity declarations that have a notation (NDATA) field. As
	-- an example, in the chunk <!ENTITY logo SYSTEM "images/logo.gif"
	-- NDATA gif> entityName would be "logo", systemId would be
	-- "images/logo.gif" and notationName would be "gif". For this example
	-- the publicId parameter would be nil. The base parameter would be
	-- whatever has been set with parser:setbase. If not set, it would be
	-- nil.
	UnparsedEntityDecl= 
		function(p,entityName,base,systemId,publicId,notationName)end,
	-- Each of these indexes can be references to functions with specific
	-- signatures as seem below. The parser constructor also checks the
	-- presence of field called _nonstrict in the callback table. If
	-- _nonstrict is absent, only valid callback names are accepted as
	-- indexes in the table (Defaultexpanded would be considered an error
	-- for example). If _nonstrict is defined any other fieldnames can be
	-- used.
	_nonstrict = nil
	}
end

stack = {}
function stack.mt(t) return {
	__index = {
		push = function(_,e)
			--_ = e and print("+"..e.name)
			table.insert(t,1,e)
		end,
		pop = function()
			--print("-"..t[1].name)
			table.remove(t,1)
		end,
		top = function()
			--_ = t[1] and print("*"..t[1].name)
			return t[1]
		end
		},
	__newindex = function(t,k,v) error("XXX") end
	}
end
stack.new = function()
	local x = {}
	setmetatable(x,stack.mt({}))
	return x
end

function lpx_cb_factory(t)
return {
	CharacterData = function(p,s)
		if t.curnode[1] == nil then
			t.curnode[1] = {s}
		end
	end,
	EndElement = function(p, elementName) 
		local tmp = t.s:top()
		if tmp ~= nil then
			table.insert(tmp,t.curnode)
			t.curnode = tmp
			t.s:pop()
		else
			t.root = t.curnode
			t.curnode = nil
			t.s = nil
		end
	end,
        StartElement= function(p, elementName, attributes)
		if t.curnode ~= nil and 
		   t.curnode[1] ~= nil and 
		   t.curnode[1].name == nil then
			table.remove(t.curnode,1)
		end
		t.s:push(t.curnode)
		t.curnode = {name=elementName}	
		table.foreach(attributes,function(k,v)
			if type(k) ~= "number" then
				t.curnode[k] = v
			end
		end)
	end,
	}
end


tab={s=stack.new()}
callbacks = lpx_cb_factory(tab)
p = lxp.new(callbacks,":")
fake_file:print()
p:parse(fake_file.s)
fake_file.s = ""
table2xml(tab.root,fake_file)
fake_file:print()
-- TODO: prendi da iun file la table con un env minimale
