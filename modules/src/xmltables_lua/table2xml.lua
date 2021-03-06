---
-- Txml to xml conversion.
--
-- This modules transforms a Txml object in an XML string. COnsider that
-- tag_name or a property name can contain <tt>__</tt> 
-- that will be converted to
-- the corresponding escape_namespace parameter.<br/><br/>
-- <tt>{tag_name = "html__a", xmlns__www="http://.../"}</tt><br/><br/>
-- will be converted to <br/><br/>
-- <tt>&lt;html:a xmlns:www="http://.../"&gt;</tt><br/><br/>
-- You may prefer writing<br/><br/>
-- <tt>{tag_name = "html:a", xmlns__www="http://.../"}</tt><br/><br/>
-- that is mostrly the same,
-- but there is no way to write <br/><br/>
-- <tt>{tag_name = "html:a", xmlns:www="http://.../"}</tt><br/><br/>
-- in LUA, so use the <tt>__</tt> for attributes. See the xml2table 
-- documentation for more infos about Txml.

MODULE_VERSION = "0.0.1"
MODULE_NAME = "table2xml"
MODULE_REQUIRE_VERSION = "0.2.0"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=table2xml.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

local Private = {}

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

function Private.escape(s,unescape)
	
   	--print("Parameters",s,unescape)
	
	if unescape == true then return s end
	
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

function Private.table2xml_aux(t,oc,c,indent,unescape)
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
	if data1 and not son then
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
		oc:write(Private.escape(data,unescape))
		return true 
	else	
		-- the parameter table
		local pt = {}
		table.foreach(t,function(k,v) 
			if k ~= "tag_name" and type(k) ~= "number" then
				k = Private.escape_ns(k,c)
				table.insert(pt,' '..k..'="'..
					Private.escape(v,unescape)..'"') 
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
					Private.table2xml_aux(v,oc,c,
						indent+2,unescape)
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

module("table2xml",package.seeall)

---
-- Txml2xml conversion.
-- @param encoding string the encoding, default is iso-8859-1.
-- @param escape_namespace string ":" is the good one, 
-- if not provided no namespacing escaping is done, read no 
-- <tt>__</tt> are converted.
-- @param unescape boolean true to not escape XML entities
-- @return string an XML string.
function table2xml(t,escape_namespace,encoding,unescape)
        local s = nil
	local fake_file = {s={}}
	function fake_file.write(self,...)
		table.insert(self.s,table.concat(arg))
	end
	function fake_file.to_string(self)
		return table.concat(self.s)
	end
	
	--print("Parameters",t,escape_namespace,encoding,unescape)
	
	fake_file:write('<?xml version="1.0" encoding="'..
		(encoding or 'iso-8859-1')..'" ?>\n')
	local f,err = 
		Private.table2xml_aux(t,fake_file,escape_namespace,0,unescape)
	if f == nil then
		print("ERROR: " .. err)
	end
	return fake_file:to_string()
end



