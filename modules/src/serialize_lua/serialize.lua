---
-- A module to save tables to strings.
-- Then the string can be executed with loadstring() obtainig a load of 
-- the table
-- 
serial = {}

--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--

local Private = {}

-- It is used internally!
function Private.serialize_val(val)
	if type(val) == "table" and getmetatable(val) == nil then
		local tmp = {}
		table.foreach(val,function (k,v)
			local s = serial.serialize(k,v)
			table.insert(tmp,s)
		end)
		return "{" .. table.concat(tmp) .. "}"
	elseif type(val) == "number" then
		return string.format("%d",val)
	elseif type(val) == "string" then
		--if string.byte(val) == string.byte("\a") then
		--	serial.OUTPUT = serial.OUTPUT .. string.sub(val,2,-1)
		--else
		--	serial.OUTPUT = serial.OUTPUT .. 
		return string.format("%q",val)
		--end
	elseif type(val) == "boolean" then
		--serial.OUTPUT = serial.OUTPUT .. 
		return tostring(val)
	else
		--
		-- print("unable to serial.serialize")
		-- serial.OUTPUT = serial.OUTPUT .. 
		return "nil"
	end
	--serial.OUTPUT = serial.OUTPUT .. string.format(";")
end

---
-- Serialize a table.
-- Should be called in this way: <code>serial.serialize("t",t)</code>
-- @return the serialization of t in the form "t=something" if name != nil,
-- 		otherwise it returns only something.
-- @param name string containing the table name or nil.
-- @param val table that will be serialized.
function serial.serialize(name,val)
	local s = ""
	if name ~= nil and type(name) ~= "number" then
		if string.find(name,"^[_%a][_%w]*$") then
			--serial.OUTPUT=serial.OUTPUT..
			s = string.format("%s=",name)
		else
			--serial.OUTPUT = serial.OUTPUT..
			s = string.format("[%q]=",name)
		end
	end
	return s .. Private.serialize_val(val) .. ";"
end

-- ------------------------------------- TEST ----------------------------------
--t = { 3, 4, ciao = "ciao1", 5, {tab = "tab1", ss = 2 }, t1 = {tab = "tab1" } }
--
--local s = serial.serialize("t1",t)
--print(s)
--
--loadstring(s)()
--
--print(serial.serialize("t1",t1))

