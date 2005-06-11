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
	local _,_,ad = string.find(mailaddress,"[^@]+@([^?]+).*")
	return ad
end

-- function to extract the username part of a mailaddress
freepops.get_name = function (mailaddress)
	local _,_,ad = string.find(mailaddress,"([^@]+)@[^?]+.*")
	return ad
end

-- function to extract the parameters part of a mailaddress
freepops.get_args = function (mailaddress)
	local _,_,ad = string.find(mailaddress,"[^@]+@[^?%s]+([?%s].*)")
	local args = {}
	local function extract_arg(s)
		local from,to = string.find(s,"=")
		if from == nil then
			return nil,nil
		else
			return string.sub(s,1,from-1),
				string.sub(s,to+1,-1)
		end
	end
	
	local function unescape(s)
		s = string.gsub(s, "+", " ")
		return string.gsub(s,"%%(%x%x)",function(n)
				return string.char(tonumber(n, 16))
			end)
	end

	if ad ~= nil then 
		ad = string.sub(ad,2,-1)
		ad = unescape(ad)
	end

	while string.len(ad or "") > 0 do
		local from,to = string.find(ad,"&")
		local param = nil
		if from ~= nil then
			param = string.sub(ad,1,to-1)
		else
			param = ad
		end
		
		local name,val = extract_arg(param)
		if name ~= nil then
			args[name] = val
		end
		
		if to ~= nil then
			ad = string.sub(ad,to+1,-1)
		else
			ad = ""
		end
	end

	return args
end

-- extracts a list of supported domain from a plugin file
-- (the plugin is executed in a protected environment, 
-- no pollution but computations are done)
function freepops.safe_extract_domains(f)
	local env = {}
	local meta_env = { __index = _G }

	-- the hack
	setmetatable(env,meta_env)
	local g, err = loadfile(f)
	if g  == nil then
		log.dbg(err)
		return nil
	end
	setfenv(g,env)
	g()
	
	-- checks 
	local check_types = function(t)
		return table.foreachi(t,function(k,v)
			if type(v) ~= "string" then
				print("'"..tostring(v).."' is not a string")
				return true
			end
			if string.byte(v) ~= string.byte("@") then
				print("'"..v.."' does not start with @")
				return true
			end
		end)
	end
	
	if env.PLUGIN_DOMAINS ~= nil then
		if type(env.PLUGIN_DOMAINS) ~= "table" then return nil end
		if check_types(env.PLUGIN_DOMAINS) then return nil end
	end
	
	if env.PLUGIN_REGEXES ~= nil then
		if type(env.PLUGIN_REGEXES) ~= "table" then return nil end
		if check_types(env.PLUGIN_REGEXES) then return nil end
	end

	-- extract
	local rc, rd = {}, {}
	if env.PLUGIN_DOMAINS ~= nil then
		table.foreachi(env.PLUGIN_DOMAINS,function(_,v)
			local x = string.sub(v,2,-1)
			table.insert(rc,x)
		end)
	end
	if env.PLUGIN_REGEXES ~= nil then
		table.foreachi(env.PLUGIN_REGEXES,function(_,v)
			local x = string.sub(v,2,-1)
			table.insert(rd,x)
		end)
	end
	
	return rc,rd
end

--searches if an unofficial plugin handles this domain
function freepops.search_domain_in_unofficial(domain)
	local function is_in_table(x,t)
		if t == nil then return false end
		return table.foreachi(t,function(_,v)
			if v == x then return true end
		end) or false
	end
	local function match_regex(x,t)
		if t == nil then return false end
		return table.foreach(t,function(_,v)
			local w,_ = string.find(x,"^" .. v .. "$")
			if w ~= nil then return true end
		end)
	end	
	local name, where = nil, nil
	table.foreach(freepops.MODULES_PREFIX_UNOFFICIAL,function(_,v)
		local it = nil
		local p_dir = function() it = lfs.dir(v) end
		local rc,err = pcall(p_dir)
		if not rc then 
			log.dbg(err)
			return
		end
		for f in it do
			if string.upper(string.sub(f,-3,-1)) == "LUA" then
				local h,rex = 
					freepops.safe_extract_domains(v.."/"..f)
				if is_in_table(domain,h) then
					name, where =  v.."/"..f, "unofficial"
					return true -- stop loop
				elseif match_regex(domain,rex) then
					name, where =  
						v.."/"..f, "unofficial(regex)"
					return true -- stop loop
				end
			end
		end	
	end)

	return name, where
end


-- to merge 2 tables (t1 wins over t)
freepops.table_overwrite = function (t,t1)  
	t = t or {}
	t1 = t1 or {}
	table.foreach(t1, function(k,v)
		t[k] = v
		end)
	return t
end

-- function that maps domains to modules
--
-- 0th: if domain d is nil then fail
-- 1st: check if a verbatim mapping exists (freepops.MODULES_MAP[d] ~= nil)
-- 2nd: check if a plugin tagged regex matches
-- 3rd: check if the mailaddress is a plugin name
-- 4th: check if an unofficial plugin matches verbatim
-- 5th: check if an unofficial plugin tagged regex matches
-- 
freepops.choose_module = function (d)
	local found, where, name, args = false, "nowhere", nil, nil
	
	-- 0th: if domain d is nil then fail
	if d == nil then 
		found, where, name, args = true, "nowhere", nil, nil 
	end

	-- 1st: check if a verbatim mapping exists 
	if not found and freepops.MODULES_MAP[d] ~= nil then
		found, where, name, args = true, "official", 
			freepops.MODULES_MAP[d].name,
			freepops.MODULES_MAP[d].args
	end
	 
	-- 2nd: check if a plugin tagged regex matches
	if not found then
		local plugins_with_regex = {}
		table.foreach(freepops.MODULES_MAP, function (k,v)
			if v.regex then
				plugins_with_regex[k] = v
			end
		end)
		table.foreach(plugins_with_regex,function(k,v)
			local x,_ = string.find(d,"^" .. k .. "$")
			if x ~= nil then
				found, where, name, args = 
					true, "official(regex)", v.name, v
				return true -- stop iteration
			end
		end)
	end
	
	-- 3rd: check if the mailaddress is a plugin name
	if not found then 
		local _,_,x = string.find(d,"^(%w+%.lua)$")
		if x ~= nil then
			found, where, name, args = 
				true, "inline", x, {}
		end
	end	
	-- 4th: check if an unofficial plugin matches verbatim
	-- 5th: check if an unofficial plugin tagged regex matches
	if not found then
		local unoff, wh = freepops.search_domain_in_unofficial(d)
		if unoff ~= nil then
			log.dbg("Using unofficial '"..unoff.."'")
			found, where, name, args = true, wh, unoff, {}
		end
	end
	
	return name, args, where 
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

	-- first check for absolute path
	try_do(0,"")
	if not got then
		table.foreach(freepops.MODULES_PREFIX,try_do)
	end
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
freepops.load_module_for = function (mailaddress,loadonly)
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
	*   http://www.freepops.org/it/lp_to_fp.shtml       *
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
	* FreePOPs needs a username with the domain part. You       *
	* must use a username in the form foo@something to use      *
	* FreePOPs. Please read the manual available at             *
	*                                                           *
        *   http://www.freepops.org/en/files/manual.pdf     *
	*                                                           *
	* or the tutorial                                           *
	*                                                           *
	*   http://www.freepops.org/en/tutorial/index.shtml *
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
	local module,args,where = freepops.choose_module(domain)
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
		--print("ARGS:")
		--table.foreach(args,print)
		--print("PARSED ARGS:")
		--table.foreach(freepops.get_args(mailaddress),print)
		--print("plugin found: ",where)

		local marg = freepops.table_overwrite(args,
			freepops.get_args(mailaddress))
		
		freepops.MODULE_ARGS = marg
		if freepops.dofile(module) ~= nil then 
			return 0 -- OK
		else
			return nil -- ERR
		end
	end
	
end

-- checks if this FreePOPs version is enough for the plugin
freepops.enough_new = function(plugin_version_string)
	local fp_version_string = os.getenv("FREEPOPS_VERSION")
	local match = "(%d+)%.(%d+)%.(%d+)"
	local _,_,fp_x,fp_y,fp_z = string.find(fp_version_string,match)
	local _,_,p_x,p_y,p_z = string.find(plugin_version_string,match)
	if fp_x == nil or fp_y == nil or fp_z == nil then
		log.error_print("Wrong FreePOPs version string format")
		return false
	end
	if p_x == nil or p_y == nil or p_z == nil then
		log.error_print("Wrong plugin REQIORE_VERSION string format.")
		log.error_print("It must be X.Y.Z (numbers only).")
		return false
	end

	if tonumber(fp_x) > tonumber(p_x) then return true end
	if tonumber(fp_x) == tonumber(p_x) and
	   tonumber(fp_y) > tonumber(p_y) then return true end
	if tonumber(fp_x) == tonumber(p_x) and
	   tonumber(fp_y) == tonumber(p_y) and	
	   tonumber(fp_z) >= tonumber(p_z) then return true end

	return false
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
			local s = "\tBUG found in '".. (d.source or "nil") ..
				"' at line "..(d.currentline or "nil")..".\n"..
				"\tFunction '".. (d.name or "anonymous") .. 
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
			local s = "\tBUG found in '".. (d.source or "nil") ..
				"' at line "..(d.currentline or "nil")..".\n"..
				"\tFunction '".. (d.name or "anonymous") .. 
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
-- freepops.dofile may be called too by the C core to execute a script that is
-- not found (and so it is searched in the standard paths)
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
-- This is only the LUA box bootstrap code. This is called to initialize the
-- lua box when freepops is started with -e or -x
-- -------------------------------------------------------------------------- --
freepops.bootstrap = function()
	load_config()
	
	-- standard lua modules that must be loaded
	if freepops.dofile("support.lua") == nil then return 1 end

	return 0 -- OK
end

-- -------------------------------------------------------------------------- --
--  This is the only (except the latter) function called from the C code. 
--  This loads the module that handles mailaddress's domain and load standard
--  LUA modules
-- -------------------------------------------------------------------------- --
freepops.init = function (mailaddress)
	freepops.bootstrap()
	
	if freepops.load_module_for(mailaddress) == nil then return 1 end
	
	-- check if the required version is older
	if not freepops.enough_new(PLUGIN_REQUIRE_VERSION) then
		log.error_print(
			"This plugin requires a newer version "..
			"of FreePOPs. Please update!")
		return 1
	end
	-- some sanity checks
	if freepops.check_global_symbols() == nil then return 1 end
	
	return 0 -- OK
end

--<==========================================================================>--
