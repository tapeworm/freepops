--<==========================================================================>--
--<=                        FREEPOPS STARTUP FILE                           =>--
--<==========================================================================>--

freepops = {}
freepops.MODULES_MAP = {}
freepops.SO = {}
freepops.MODULE_ARGS = nil

--<==========================================================================>--
-- This metatable/metamethod avoid accessing wrong fields of the tabe
fp_m = { 
	__index = function(table,k)
		if k == "MODULE_ARGS" then
			return nil
		else
			local err = string.format(
				"Unable to access to 'freepops.%s'\n",k)
			error(err) 
		end 
	end
}

setmetatable(freepops,fp_m)

--<==========================================================================>--
-- these are global helpers for all freepops modules

-- function to extract domain part of a mailaddress
freepops.get_domain = function (mailaddress)
	local _,_,ad = string.find(mailaddress,"[^@]+@([%-%_%.%a%d]+)")
	return ad
end

-- function to extract the username part of a mailaddress
freepops.get_name = function (mailaddress)
	local _,_,ad = string.find(mailaddress,"([^@]+)@[%-%_%.%a%d]+")
	return ad
end

-- function that maps domains to modules
freepops.choose_module = function (d)
	if d == nil then return nil,nil end
	if freepops.MODULES_MAP[d] == nil then return nil,nil end
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
	-- helpers
	local function err_format(dom,mail) 
		return string.format(
			"Unable to find a module that handles '%s' domain,"..
			" requested by '%s' mail account\n",dom,mail)
	end
	local function err_rtfm()
		return [[
		
	*************************************************************
	*                      LEGGIMI                              *
	*                                                           * 
	* Sembra che tu abbia usato uno username privo della        *
	* parte @qualcosa. FreePOPs ha bisogno di username con      *
	* un dominio. Se eri un utente LiberoPOPs puoi leggere      *
	*                                                           *
	*   http://freepops.sourceforge.net/it/lp_to_fp.shtml       *
	*                                                           *
	* che spiega cosa devi esattamente fare. Per favore non     *
	* mettere richieste di aiuto sul forum se non hai           *
	* semplicemente messo il dominio nello username             *
	*                                                           *
	*************************************************************
]],[[
	
	*************************************************************
	*                      README                               *
	*                                                           *
	* FreePOPs needs a username wit ha domain part. You         *
	* must use a username in the form foo@something to use      *
	* FreePOPs. Please read the manual available at             *
	*                                                           *
        *   http://freepops.sourceforge.net/en/files/manual.pdf     *
	*                                                           *
	* or the tutorial                                           *
	*                                                           *
	*   http://freepops.sourceforge.net/en/tutorial/index.shtml *
	*                                                           *
	*************************************************************
]]
	end
	
	-- preventive check
	local accept,why = freepops.match_address(mailaddress,
		freepops.ACCEPTED_ADDRESSES)

	if not accept then
		local reject,why = freepops.match_address(mailaddress,
			freepops.REJECTED_ADDRESSES)
		if reject then
			log.say("Rejecting '" .. mailaddress .. 
				"' cause matched '" .. why .."'\n")
			return nil -- ERR
		end
	else
		log.dbg("Accepting '" .. mailaddress .. 
			"' cause matched '" .. why .."'\n")
	end

	-- the stuff
	local domain = freepops.get_domain(mailaddress)
	local module,args = freepops.choose_module(domain)
	if module == nil then
		if domain ~= nil then
			log.error_print(err_format(domain,mailaddress))
		else
			local it,en = err_rtfm()
			log.error_print(it)
			log.error_print(en)
		end
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

-- makes tab members globals
freepops.export = function(tab)
	local _export = function(name,value) 
		_G[name]=value 
	end
	table.foreach(tab,_export)
end

-- required methods
local pop3_methods = {
	"user","pass",
	"list","list_all",
	"uidl","uidl_all",
	"stat",
	"retr","top",
	"rset","noop","dele",
	"quit","quit_update",
	"init",
}

-- checks if the plugin has declared all required methods
freepops.check_global_symbols = function()
	for _,v in ipairs(pop3_methods) do
		if _G[v] == nil then
			log.error_print("The plugin has not declared '"..v.."'")
			return nil
		end
	end
	return true
end

-- checks for wrong globals usage
freepops.set_sanity_checks = function()
	-- no more globals can be declared after this (except _)
	setmetatable(_G,{
		__index = function(t,k)
			local d = debug.getinfo(2,"lSn")or debug.getinfo(1,"lS")
			local s = "\tBUG found in '".. d.source ..
				"' at line " .. d.currentline .. ".\n"..
				"\tFunction '".. d.name .. 
				"' uses an undefined global '" ..k.. "'\n"..[[

	This is a sanity check added by freepops.set_sanity_checks() that
	prevents the plugin to access undeclared globals.
	This avoids some hard-to-detect bugs.
	]]
			log.say(s.."\n")
			error(s)
		end,
		__newindex = function(t,k,v)
			if k == "_" then rawset(_G,k,v) return end
			local d = debug.getinfo(2,"lSn")or debug.getinfo(1,"lS")
			local s = "\tBUG found in '".. d.source ..
				"' at line " .. d.currentline..".\n"..
				"\tFunction '".. d.name .. 
				"' sets an undefined global '" .. k .. "'\n"..[[
				
	This is a sanity check added by freepops.set_sanity_checks() that
	prevents the plugin to create new global variables. This means you
	must use the 'local' keyword or declare a global table 
	(ex. plugin_state) and use it as the global state of the plugin. 
	This avoids some hard-to-detect bugs.
	]]
			log.say(s.."\n")
			error(s)
		end
	})
end

-- checks if this version of FP is SSL enabled
-- !! must be called after loading the browser module !!
function freepops.need_ssl()
	local c = browser.ssl_enabled()
	if not c then
		local s = [[

	This plugin needs a SSL-enabled version of FreePOPs. If you are a 
	windows user, please download and install the -SSL version of FreePOPs.
	If you are a unix user, this means you have to install an SSL library,
	like OpenSSL, and make libcURL aware of this (maybe you need to 
	recompile them).
	]]
	
		log.say(s.."\n")
		error(s)
	end
end


-- checks if the address a is matched by the strings defined in table t
function freepops.match_address(a,t)
	local why = ""
	local rc = table.foreach(t,function(k,v)
		local capt = "^(" .. v .. ")$"
		local _,_,x = string.find(a,capt)
		if x ~= nil then 
			why = v
			return true
		end
	end)
	
	if rc then 
		return rc,why
	else
		return false,nil
	end
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

	if freepops.check_global_symbols() == nil then return 1 end

	return 0 -- OK
end

--<==========================================================================>--
