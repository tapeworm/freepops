t = 	{
	-- name is reserved and is the tag name
	name="tag1",
	-- attributs if different from name
	param1="val1",
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

-- XXX la chiamo solo su data ma non sui param, va bene? XXX
-- si dovrebbe usare per controllare anche i nomi dei parametri	
function escape(s)
	return (string.gsub(s,[[([><"'&])]],function(x)
		if x == ">" then
			return "&gt;"
		elseif x == "<" then
			return "&lt;"
		elseif x == '"' then
			return "&quot;"
		-- XXX controlla cosa e' apos XXX
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
				table.insert(pt,k..'="'..v..'" ') 
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
			oc:write(c_p.."<"..name.." "..table.concat(pt).."/>")
		else
			local no_cp = false
			oc:write(c_p.."<"..name.." "..table.concat(pt)..">")
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
				oc:write("</"..name.." >")
			else
				oc:write(c_p.."</"..name.." >")
			end
		end
		oc:write('\n')
	end
end

function table2xml(t,oc)
	oc:write('<?xml version="1.0" encoding="iso-8859-1" ?>\n')
	table2xml_aux(t,oc,0)
end

table2xml(t,io.stdout)
