---
-- A module to save tables to strings.
-- Then the string can be executed with loadstring() obtainig a load of 
-- the table
-- 

MODULE_VERSION = "0.0.1"
MODULE_NAME = "serial"
MODULE_REQUIRE_VERSION = "0.0.99"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=serial.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

module("serial",package.seeall)

-- It is used internally!
local function serialize_val(val)
	if type(val) == "table" and getmetatable(val) == nil then
		local tmp = {}
		table.foreach(val,function (k,v)
			local s = serialize(k,v)
			table.insert(tmp,s)
		end)
		return "{" .. table.concat(tmp) .. "}"
	elseif type(val) == "number" then
		return string.format("%d",val)
	elseif type(val) == "string" then
		return string.format("%q",val)
	elseif type(val) == "boolean" then
		return tostring(val)
	else
		return "nil"
	end
end

---
-- Serialize a table.
-- Should be called in this way: <code>serial.serialize("t",t)</code>
-- @return the serialization of t in the form "t=something" if name != nil,
-- 		otherwise it returns only something.
-- @param name string containing the table name or nil.
-- @param val table that will be serialized.
function serialize(name,val)
	local s = ""
	if name ~= nil and type(name) ~= "number" then
		if string.find(name,"^[_%a][_%w]*$") then
			s = string.format("%s=",name)
		else
			s = string.format("[%q]=",name)
		end
	end
	return s .. serialize_val(val) .. ";"
end

