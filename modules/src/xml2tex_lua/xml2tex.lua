--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

MODULE_VERSION = "0.0.1"
MODULE_NAME = "xml2tex"
MODULE_REQUIRE_VERSION = "0.2.0"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=xml2tex.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

require("xml2table")

local private = {}
private.multilang = {}
private.multilang["author"] = {}
private.multilang["author"].it = "Autore"
private.multilang["author"].en = "Author"
private.multilang["authors"] = {}
private.multilang["authors"].it = "Autori"
private.multilang["authors"].en = "Authors"
private.multilang["name"] = {}
private.multilang["name"].it = "Nome"
private.multilang["name"].en = "Name"
private.multilang["version"] = {}
private.multilang["version"].it = "Versione"
private.multilang["version"].en = "Version"
private.multilang["requires"] = {}
private.multilang["requires"].it = "Necessita di"
private.multilang["requires"].en = "Requires"
private.multilang["license"] = {}
private.multilang["license"].it = "Licenza"
private.multilang["license"].en = "License"
private.multilang["url"] = {}
private.multilang["url"].it = "Scaricabile da"
private.multilang["url"].en = "Available at"
private.multilang["homepage"] = {}
private.multilang["homepage"].it = "Homepage"
private.multilang["homepage"].en = "Homepage"
private.multilang["domain"] = {}
private.multilang["domain"].it = "Dominio"
private.multilang["domain"].en = "Domain"
private.multilang["domains"] = {}
private.multilang["domains"].it = "Domini"
private.multilang["domains"].en = "Domains"
private.multilang["regex"] = {}
private.multilang["regex"].it = "Dominio(regex)"
private.multilang["regex"].en = "Domain(regex)"
private.multilang["regexes"] = {}
private.multilang["regexes"].it = "Domini(regex)"
private.multilang["regexes"].en = "Domains(regex)"
private.multilang["description"] = {}
private.multilang["description"].it = "Descrizione"
private.multilang["description"].en = "Description"
private.multilang["parameter"] = {}
private.multilang["parameter"].it = "Paramtero"
private.multilang["parameter"].en = "Parameter"
private.multilang["parameters"] = {}
private.multilang["parameters"].it = "Parametri"
private.multilang["parameters"].en = "Parameters"
private.multilang["tpl"] = {}
private.multilang["tpl"].it = "Questo plugin supporta i seguenti domini: "
private.multilang["tpl"].en = "This plugin supports these domains: "

function private.E(s)
	s = string.gsub(s,"_","\\_")
	s = string.gsub(s,"#","$\\sharp$")
	s = string.gsub(s,"&egrave;","\\`e")
	s = string.gsub(s,"&agrave;","\\`a")
	s = string.gsub(s,"&ograve;","\\`o")
	s = string.gsub(s,"&ugrave;","\\`u")
	s = string.gsub(s,"&igrave;","\\`i")
	s = string.gsub(s,"&apos;","`")
	s = string.gsub(s,"&quote;","``")
	s = string.gsub(s,"&quot;","``")
	s = string.gsub(s,"%%","")
	s = string.gsub(s,"%.%*","*")
	s = string.gsub(s,"<br/>","\n\n")
	return s
end

function main(arg)

	if table.getn(arg) <= 1 then
		print("usage: xml2tex file.xml lang [brief]")
		os.exit(1)
	end

	filename = string.match(arg[1],"(.*).xml")

	if filename == nil then
		print("filename must be 'pluginname.lua.xml'")
		os.exit(1)
	end

	filename1 = string.match(filename,".*/([^/]+)")

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

	brief = arg[3]
	if brief then
	-- BRIEF -------------------------------------
		s = ""
		s = s .. "\\item["..private.E(plugin_name)..
			" ("..private.E(t.name._content)..
			")]:\\\\\n"..private.multilang["tpl"][lang]
		if t.domains ~= nil and table.getn(t.domains) > 0 then
			xml2table.forach_son(t.domains,"domain",function(k)
				s = s .. private.E(k._content)..", "
			end)
			if string.sub(s,-2,-1) == ", " then
				s = string.sub(s,1,-3) .. "\n"
			end
		end
		if t.regexes ~= nil and table.getn(t.regexes) > 0 then
			xml2table.forach_son(t.regexes,"regex",function(k)
				s = s .. private.E(k._content)..", "
			end)
			if string.sub(s,-2,-1) == ", " then
				s = string.sub(s,1,-3) .. "\n"
			end
		end

	else
	-- COMPLETE ----------------------------------
	s = ""
	s = s .. "\\subsection{"..private.E(plugin_name).."}\n"
	s = s .. "\\begin{description}\n"
	s =s.."\\item["..private.multilang["name"][lang]..":]"..
		private.E(t.name._content).."\n"
	s = s .. "\\item["..private.multilang["version"][lang]..":]"..
		private.E(t.version._content).."\n"
	s = s .. "\\item["..private.multilang["requires"][lang]..":]FreePOPs "..
		private.E(t.require_version._content).."\n"
	s = s .. "\\item["..private.multilang["license"][lang]..":]"..
		private.E(t.license._content).."\n"
	s = s .."\\item["..private.multilang["url"][lang]..":]"..
		private.E(t.url._content).."\n"
	s = s .. "\\item["..private.multilang["homepage"][lang]..":]"..
		private.E(t.homepage._content).."\n"
	--------
	if table.getn(t.authors) > 1 then
		s = s .. "\\item["..private.multilang["authors"][lang]..":]"
	else
		s = s .. "\\item["..private.multilang["author"][lang]..":]"
	end
	xml2table.forach_son(t.authors,"author",function(k)
		s = s .. private.E(k.name._content).." <"..
			private.E(k.contact._content)..">, "
	end)
	if string.sub(s,-2,-1) == ", " then
		s = string.sub(s,1,-3) .. "\n"
	end
	-------
	if (t.domains ~= nil) then
		if table.getn(t.domains) > 1 then
			s = s .. "\\item["..
				private.multilang["domains"][lang]..":]"
		else
			s = s .. "\\item["..
				private.multilang["domain"][lang]..":]"
		end
		xml2table.forach_son(t.domains,"domain",function(k)
			s = s .. private.E(k._content)..", "
		end)
		if string.sub(s,-2,-1) == ", " then
			s = string.sub(s,1,-3) .. "\n"
		end
	end
	if(t.regexes ~= nil) then
		if table.getn(t.regexes) > 1 then
			s = s .. "\\item["..
				private.multilang["regexes"][lang]..":]"
		else
			s = s .. "\\item["..
				private.multilang["regex"][lang]..":]"
		end
		xml2table.forach_son(t.regexes,"regex",function(k)
			s = s .. private.E(k._content)..", "
		end)
		if string.sub(s,-2,-1) == ", " then
			s = string.sub(s,1,-3) .. "\n"
		end
	end
	------
	s = s .. "\\item["..private.multilang["description"][lang]..":]"
	xml2table.forach_son(t.descriptions,"description",function(k)
			if k.lang == lang then
				s = s .. private.E(k._content).."\n"
				return true
			end
		end)
	------
	if table.getn(t.parameters) > 0 then
		if table.getn(t.parameters) > 1 then
			s = s .."\\item["..
				private.multilang["parameters"][lang]..":]\n"	
		else	
			s = s .. "\\item["..
				private.multilang["parameter"][lang]..":]\n"	
		end
		s = s .."\\hspace{\\stretch{1}}  \\begin{description}\n"
		xml2table.forach_son(t.parameters,"parameter",function(k)
			s = s .."    \\item["..private.E(k.name).."]"
			xml2table.forach_son(k.descriptions,"description",
			function(k)
				if k.lang == lang then
					s = s .. private.E(k._content).."\n"
					return true
				end
			end)
		end)
		s = s .."  \\end{description}\n"
	end
	s = s .. "\\end{description}\n"
	end

	print(s)
	return 0
end
