---
-- A module to save tables to strings
-- Then the string can be executed with loadstring() obtainig a load of 
-- the table

serial = {}

---
-- This string will be filled with the serialized form of the table.
-- Remember to call serial.init() before begin!
serial.OUTPUT="read-only"


---
-- Initializes the module.
-- Must be used before serializing a table.
function serial.init()
	serial.OUTPUT = ""
end

---
-- Do not use this.
-- It is used internally!
function serial._serialize_val(val)
	if type(val) == "table" then
		serial.OUTPUT = serial.OUTPUT .. string.format("{")
		table.foreach(val,serial.serialize)
		serial.OUTPUT = serial.OUTPUT .. string.format("}")
	elseif type(val) == "number" then
		serial.OUTPUT = serial.OUTPUT .. string.format("%d",val)
	elseif type(val) == "string" then
		if string.byte(val) == string.byte("\a") then
			serial.OUTPUT = serial.OUTPUT .. string.sub(val,2,-1)
		else
			serial.OUTPUT = serial.OUTPUT .. 
				string.format("\"%s\"",val)
		end
	elseif type(val) == "boolean" then
		serial.OUTPUT = serial.OUTPUT .. tostring(val)
	else
		--
		--print("unable to serial.serialize")
		serial.OUTPUT = serial.OUTPUT .. "nil"
	end
	serial.OUTPUT = serial.OUTPUT .. string.format(";")
end

---
-- Serialize a table.
-- Should be called in this way: <code>serial.serialize("t",t)</code>
-- @return Sets <code>serial.OUTPUT</code> to the string representing the table.
-- @param name string containig the table name.
-- @param val table that will be serialized.
function serial.serialize(name,val)
	if type(name) ~= "number" then
		if string.find(name,"[%-%.%%]") ~= nil then
			serial.OUTPUT=serial.OUTPUT..string.format("['%s']=",name)
		else
			serial.OUTPUT = serial.OUTPUT..string.format("%s=",name)
		end
	end
	serial._serialize_val(val)
end

-- ------------------------------------- TEST ----------------------------------
--t = { 3, 4, ciao = "ciao1", 5, {tab = "tab1", ss = 2 }, t1 = {tab = "tab1" } }
--
--serial.init()
--serial.serialize("t1",t)
--print(serial.OUTPUT)
--
--loadstring(serial.OUTPUT)()
--
--serial.init()
--serial.serialize("t1",t1)
--print(serial.OUTPUT)

