dofile "modules/include/xml2table.lua"

if table.getn(arg) <= 1 then
	print("usage: "..arg[0].." file.xml lang")
	os.exit(1)
end

_,_,filename = string.find(arg[1],"(.*).xml")

if filename == nil then
	print("filename must be 'pluginname.lua.xml'")
	os.exit(1)
end

_,_,filename1 = string.find(filename,".*/([^/]+)")

plugin_name = filename1 or filename

f,err = io.open(arg[1])
if f == nil then
	print(err)
	os.exit(1)
end
xml = f:read("*a")
f:close()

t = xml2table.xml2table(xml)

if t == nil then
	os.exit(1)
end

lang = arg[2]
if string.len(arg[2]) ~= 2 then
	print("lang must be a 2 chars string")
	os.exit(1)
end

multilang = {}
multilang["author"] = {}
multilang["author"].it = "Autore"
multilang["author"].en = "Author"
multilang["authors"] = {}
multilang["authors"].it = "Autori"
multilang["authors"].en = "Authors"
multilang["name"] = {}
multilang["name"].it = "Nome"
multilang["name"].en = "Name"
multilang["version"] = {}
multilang["version"].it = "Versione"
multilang["version"].en = "Version"
multilang["requires"] = {}
multilang["requires"].it = "Necessita di"
multilang["requires"].en = "Requires"
multilang["license"] = {}
multilang["license"].it = "Licenza"
multilang["license"].en = "License"
multilang["url"] = {}
multilang["url"].it = "Scaricabile da"
multilang["url"].en = "Available at"
multilang["homepage"] = {}
multilang["homepage"].it = "Homepage"
multilang["homepage"].en = "Homepage"
multilang["domain"] = {}
multilang["domain"].it = "Dominio"
multilang["domain"].en = "Domain"
multilang["domains"] = {}
multilang["domains"].it = "Domini"
multilang["domains"].en = "Domains"
multilang["description"] = {}
multilang["description"].it = "Descrizione"
multilang["description"].en = "Description"
multilang["parameter"] = {}
multilang["parameter"].it = "Paramtero"
multilang["parameter"].en = "Parameter"
multilang["parameters"] = {}
multilang["parameters"].it = "Parametri"
multilang["parameters"].en = "Parameters"

s = ""
s = s .. "\\subsection{"..plugin_name.."}\n"
s = s .. "\\begin{description}\n"
s = s .. "\\item["..multilang["name"][lang]..":]"..t.name._content.."\n"
s = s .. "\\item["..multilang["version"][lang]..":]"..t.version._content.."\n"
s = s .. "\\item["..multilang["requires"][lang]..":]FreePOPs "..t.require_version._content.."\n"
s = s .. "\\item["..multilang["license"][lang]..":]"..t.license._content.."\n"
s = s .. "\\item["..multilang["url"][lang]..":]"..t.url._content.."\n"
s = s .. "\\item["..multilang["homepage"][lang]..":]"..t.homepage._content.."\n"
--------
if table.getn(t.authors) > 2 then
	s = s .. "\\item["..multilang["authors"][lang]..":]"
else
	s = s .. "\\item["..multilang["author"][lang]..":]"
end
xml2table.forach_son(t.authors,"author",function(k)
	s = s .. k.name._content.." <"..k.contact._content..">, "
end)
if string.sub(s,-2,-1) == ", " then
	s = string.sub(s,1,-3) .. "\n"
end
-------
if table.getn(t.domains) > 2 then
	s = s .. "\\item["..multilang["domains"][lang]..":]"
else
	s = s .. "\\item["..multilang["domain"][lang]..":]"
end
xml2table.forach_son(t.domains,"domain",function(k)
	s = s .. k._content..", "
end)
if string.sub(s,-2,-1) == ", " then
	s = string.sub(s,1,-3) .. "\n"
end
------
s = s .. "\\item["..multilang["description"][lang]..":]"
xml2table.forach_son(t.descriptions,"description",function(k)
		if k.lang == lang then
			s = s .. k._content.."\n"
			return true
		end
	end)
------
if table.getn(t.domains) > 2 then
	s = s .. "\\item["..multilang["domains"][lang]..":]"
else
	s = s .. "\\item["..multilang["domain"][lang]..":]"
end
xml2table.forach_son(t.domains,"domain",function(k)
	s = s .. k._content..", "
end)
if string.sub(s,-2,-1) == ", " then
	s = string.sub(s,1,-3) .. "\n"
end
--
if table.getn(t.parameters) > 0 then
	if table.getn(t.parameters) > 1 then
		s = s .. "\\item["..multilang["parameters"][lang]..":]\n"	
	else	
		s = s .. "\\item["..multilang["parameter"][lang]..":]\n"	
	end
	s = s .."  \\begin{description}\n"
	xml2table.forach_son(t.parameters,"parameter",function(k)
		s = s .."    \\item["..k.name.."]"
		xml2table.forach_son(k.descriptions,"description",function(k)
			if k.lang == lang then
				s = s .. k._content.."\n"
				return true
			end
		end)
	end)
	s = s .."  \\end{description}\n"
end
s = s .. "\\end{description}\n"

print(s)
