--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--

local Private = {}

function Private.escape(s)
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

Private.Valid_Tables = [[

Valid tables are {\"pcdata\"} and 
{tag_name="body",color="red", {tag_name...},{tag_name...},...} and 
{tag_name="body",{"pcdata"}"}
]]


function Private.errorize(err,t)
	return "Invalid Table ("..err.."): " .. 
		(t.tag_name or t[1] or "nil") .. "\n" ..
		Private.Valid_Tables
end

function Private.escape_ns(s,c)
	if c then 
		return (string.gsub(s,"__",c))
	else
		return s
	end
end

function Private.table2xml_aux(t,oc,c,indent)
	if t == nil then
		return true
	end
	local c_p = string.rep(" ",indent)
	-- sanity checks
	local name = t.tag_name
	local data = t[1]
	local data1 = t[2]
	local son = nil
	if type(data) == "table" then
		son = data.tag_name
	end
	
	if name == nil and data == nil then
		local err = "Each table must contain a \"data\" alone "..
			"or a 'tag_name' field"
		return nil,Private.errorize(err,t)
	end
	if name == nil and son ~= nil then
		local err = "A pcdata field can't have sons"
		return nil,Private.errorize(err,t)
	end
	if data2 and not son then
		local err = "Only one pcdata son is allowed" 
		return nil,Private.errorize(err,t)
	end
	if name == nil and not data then
		local err = "No tag_name, no data" 
		return nil,Private.errorize(err,t)
	end

	-- serializing
	if data ~= nil and name == nil and not son then
		-- we have a pcdata field
		oc:write(Private.escape(data))
		return true 
	else	
		-- the parameter table
		local pt = {}
		table.foreach(t,function(k,v) 
			if k ~= "tag_name" and type(k) ~= "number" then
				k = Private.escape_ns(k,c)
				table.insert(pt,' '..k..'="'..
					Private.escape(v)..'"') 
			end 
		end)
		name = Private.escape_ns(name,c)
		if not data then
			-- we have a <tag/> 
			oc:write(c_p.."<"..name..table.concat(pt).." />\n")
		else
			-- we have a <tag>...</tag>
			oc:write(c_p.."<"..name..table.concat(pt)..">")
			if son then 
				oc:write("\n")
			end
			table.foreachi(t,function(_,v)
				local f,err = 
					Private.table2xml_aux(v,oc,c,indent+2)
				if f == nil then
					return nil,err
				end
			end)
			if son then 
				oc:write(c_p)
			end
			oc:write("</"..name..">\n")
		end
		return true
	end
end

--==========================================================================--
-- extern function
--==========================================================================--

table2xml = {}

function table2xml.table2xml(t,escape_namespace,encoding)
	fake_file = {s={}}
	function fake_file.write(self,...)
		table.insert(self.s,table.concat(arg))
	end
	function fake_file.to_string(self)
		return table.concat(self.s)
	end
	
	fake_file:write('<?xml version="1.0" encoding="'..
		(encoding or 'iso-8859-1')..'" ?>\n')
	local f,err = Private.table2xml_aux(t,fake_file,escape_namespace,0)
	if f == nil then
		print("ERROR: " .. err)
	end
	return fake_file:to_string()
end



