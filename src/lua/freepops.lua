--<==========================================================================>--
--<=                        FREEPOPS STARTUP FILE                           =>--
--<==========================================================================>--

freepops = {}
freepops.MODULES_MAP = {}
freepops.SO = {}
freepops.MODULE_ARGS = nil
fp_m = { __index = function(table,k) error(string.format("Unable to access to 'freepops.%s'\n",k)) end }
setmetatable(freepops,fp_m)

--<==========================================================================>--
-- these are global helpers for all freepops modules

-- function to extract domain part of a mailaddress
freepops.get_domain = function (mailaddress)
	local _,_,ad = string.find(mailaddress,"[%-_\.%a%d]+@([%-_\.%a%d]+)")
	return ad
end

-- function that maps domains to modules
freepops.choose_module = function (d)
	if d == nil then return nil,nil end
	return 	freepops.MODULES_MAP[d].name,freepops.MODULES_MAP[d].args
end

-- dofile with freepops.MODULES_PREFIX path
freepops.dofile = function (file)
	local got = nil
	local try_do = function (index,path)
		local f,_ = io.open(path..file,"r")
		if f ~= nil then
			io.close(f)
			freepops.__dofile(path..file)
			got = 1
			return 0 -- stop looping
		else
			return nil -- continue looping
		end
	end
	table.foreach(freepops.MODULES_PREFIX,try_do)
	if not got then
		log.error_print(string.format("Unable to find '%s'\n",file))
		log.error_print(string.format("Path is '%s'\n",
			table.concat(freepops.MODULES_PREFIX,":")))
	end
	return got
end
freepops.__dofile = dofile
dofile = freepops.dofile

-- load a shared library with freepops.MODULES_PREFIX path
freepops.loadlib = function (file,fname)
	local got = nil
	local try_do = function (index,path)
		local f,_ = io.open(path..file,"r")
		if f ~= nil then
			io.close(f)
			local g,err = freepops.__loadlib(path..file,fname)
			if not g then
				log.error_print(path..file..": "..err.."\n")
				return nil
			else
				g()
				got = 1
				return 0 -- stop looping
			end
		else
			return nil -- continue looping
		end
	end
	local function foo() end
	-- check if already loaded
	if freepops.SO[file] then
		return foo
	end
	-- load it
	table.foreach(freepops.MODULES_PREFIX,try_do)
	-- check result
	if not got then
		log.error_print(string.format("Unable to load '%s'\n",file))
		log.error_print(string.format("Path is '%s'\n",
			table.concat(freepops.MODULES_PREFIX,":")))
		return nil
	else
		freepops.SO[file] = 1	
		return foo
	end
end

-- prevent using the real loadlib
freepops.__loadlib = loadlib
loadlib = freepops.loadlib

-- load needed module for handling domain
freepops.load_module_for = function (mailaddress)
	local domain = freepops.get_domain(mailaddress)
	local module,args = freepops.choose_module(domain)
	if module == nil then
		log.error_print(string.format(
			"Unable to find a module that handles '%s' domain,"..
			" requested by '%s' mail account\n",
			domain or "",mailaddress))
		return nil --ERR
	else
		freepops.MODULE_ARGS = args
		if freepops.dofile(module) ~= nil then 
			return 0 -- OK
		else
			return nil -- ERR
		end
	end
	
end

freepops.export = function(tab)
	local _export = function(name,value) 
		_G[name]=value 
	end
	table.foreach(tab,_export)
end

--<==========================================================================>--
-- Local functions

-- config file loading
local function load_config()

	local paths = { 
		"/etc/freepops/",
		"./",
		os.getenv("FREEPOPSLUA_PATH") or "./" ,
	}

	local try_load = function (_,p)
		local h = loadfile(p .. "config.lua")
		if h ~= nil then 
			h() 
			return true
		else
			return nil
		end
	end

	local rc = table.foreachi(paths,try_load)

	if rc == nil then
		error("Unable to load config.lua. Path is "..
			table.concat(paths,":"))
	end

end

--<==========================================================================>--
-- This is the function freepops calls

-- -------------------------------------------------------------------------- --
--  This is the only function called from the C code. This loads the module
--  that handles mailaddress's domain and load standard LUA modules
-- -------------------------------------------------------------------------- --
freepops.init = function (mailaddress)
	load_config()

	-- standard lua modules that must be loaded
	if freepops.dofile("support.lua") == nil then return 1 end
	
	if freepops.load_module_for(mailaddress) == nil then return 1 end

	return 0 -- OK
end

--<==========================================================================>--
