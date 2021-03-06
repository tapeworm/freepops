---
-- Do not use this directly.
-- browser uses this module for his internal purpose.
-- Only one function is available to the end user.
-- Incorporating jbobowski Gmail fix posted 26 April 2006.

MODULE_VERSION = "0.1.8"
MODULE_NAME = "browser.cookie"
MODULE_REQUIRE_VERSION = "0.2.0"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=browser.cookie.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

local Private = {}

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL
--============================================================================--

--<==========================================================================>--
-- build data structures for parsing

-- create a lua regex expression to capture v in both uppercase/lowercase
function Private.create_match(v)
	local vU = string.upper(v)
	local vL = string.lower(v)
	local r = {}
	for i=1,string.len(v) do
		r[i]="["..string.char(string.byte(vU,i))..
			string.char(string.byte(vL,i)).."]"
	end
	return "("..table.concat(r)..")"
end

-- fields of a cooker record
Private.cookie_av={
	"domain",
	"path",
	"comment",

--	"secure",
--	commented since the parser is too greedy and eats with
--	this rules also something like "aaa_secure" (plugin name).
--	not only a "secure" attribute.

	"version",
	"max-age",
	"expires"
}

-- some captures for the cookie fields
Private.value = {}
Private.value.token='=%s*("?[^";]*"?)'
Private.value.name="^(%s*[^=]+)"
Private.value.domain='=%s*("?%.?[%w%.%_%-%%%/%+%-%*]+"?)'
Private.value.expires="=%s*(%a+%s*,%s*[%w%:%s%-]+)"
Private.value.secure="(%s?)"
Private.value.version="=%s*(%d)"

Private.left_table = {}

-- puts in left_table the map: name -> expression_to_capture_name_value
-- used for catching the left part of an equality,
-- consider that the left_table["domain"] will capture
-- "([Dd][Oo][Mm][Aa][Ii][Nn])" that will be used to find the first part of
-- a string like:
-- DOMAIN = VALUE
table.foreach(Private.cookie_av,function(_,v)
	Private.left_table[v] = Private.create_match(v)
	end)
Private.left_table["name"]=Private.value.name

-- eat generates functions that will be called on the cookie string s and
-- the storage table t, these eating functions will put in
-- t[name] the capture
function Private.eat(name,value)
	return function(s,t)
		local b,e,l,r =
			string.find(s,Private.left_table[name].."%s*"..value)
		if b then
			t[name]= r
			return string.sub(s,1,b-1)..string.sub(s,e+1,-1)
		end
		return s
	end
end

function Private.eat2(name1,name2,value)
	return function(s,t)
		local b,e,l,r =
			string.find(s,Private.left_table[name1].."%s*"..value)
		if b then
			t[name1]=l
			t[name2]=r
			return string.sub(s,1,b-1)..string.sub(s,e+1,-1)
		end
		return s
	end
end

-- temp table used to build the following one
Private.types = {}
table.foreach(Private.cookie_av,function(_,v)
	Private.types[v] = Private.value[v] or Private.value["token"]
	end)
Private.types["name"] = Private.value["token"]

-- this table will contains the eaters funcions for all the elements in the
-- cookie grammar, see cookie_av
Private.syntax = {}
table.foreach(Private.cookie_av,function(_,v)
	Private.syntax[v] = Private.eat(v,Private.types[v])
	end)
Private.syntax["name"] = Private.eat2("name","value",Private.types["name"])

--<==========================================================================>--
-- helper functions

-- given a host h and a string s, this returns a table with all the cookie
-- fields plus host h
function Private.parse_cookie(s,h)
	local t = {}
	local s1 = s
	table.foreach(Private.syntax,function(n,f) s1 = f(s1,t) end)
	if t.path == nil then t.path='/' end
	if t.expires ~= nil then
	    -- Fix to deal with a date expiration that is larger than our data structure can handle.  This needs to be revisited
		-- in at least 2019.
		--
        t.expires = string.gsub(t.expires, "20[3-9]+", "2020")
		local tmp = getdate.toint(t.expires)
		t["expires-raw"] = t["expires"]
		if tmp ~= -1 then
			t["expires"] = tmp
		end
	end
	if t.domain == nil then
		if h == nil then
			error("parse_cookies cant be called with h = nil")
		end
		t.domain = h
	end
	t.timestamp = os.time()
	t.host = h
	return t
end

 -- checks if the cookie has to be purged
 function Private.is_expired(c)
     local date = os.time()

     if c["expires"] ~= nil then
		 if c["expires"] < date then
             return true
         end
     end

     if c["max-age"] then
      	-- this should not be necessary, but...
      	if c["max-age"] ~= nil and type(c["max-age"]) == "string" then
      		c["max-age"] = getdate.toint(c["max-age"])
          log.say("cookie.Private.is_expired - max-age conversion")
      	end
         if c["max-age"] > date then
             return true
		end
	end

	-- this should not be necessary, but...
	if c["expires"] ~= nil and type(c["expires"]) == "string" then
		c["expires"] = getdate.toint(c["expires"])
	end

	if c["expires"] and c["timestamp"] then
		if os.difftime(date,c["timestamp"]) > c["expires"] then
			return true
		end
	end
	return false
end

-- puts a uri in a table containing the / separated parts
function Private.split_uri(path)
	local t = {}
	if not path then return t end
	for w in string.gfind(path,"/[%w%%%_%.%~]*") do
		table.insert(t,string.sub(w,2,-1))
	end
	return t
end

-- counts how many parts of path are in common
function Private.subpath_len(path,sub)
	if not sub then
		return -1 --no path
	end
	--print(path,sub)
	local t1 = Private.split_uri(path)
	local t2 = Private.split_uri(sub)
	local n = 0
	local function count(i,v)
		if t2[i] == v then
			n = n + 1
		else
			return false
		end
	end
	table.foreachi(t1,count)
	return n
end

--<==========================================================================>--

module("browser.cookie",package.seeall)

-- parse
function parse_cookies(s,h)
	if s then
		local r = {}
		table.insert(r,Private.parse_cookie(s,h))
		return r
	else
		return nil
	end
end

-- merges two tables of cookies
function merge(t2,t1)
	if not t1 then
		return
	end
	clean_expired(t1)
	clean_expired(t2)
	table.foreach(t1,function(_,c)
		local match = 0
		table.foreach(t2,function(_,c2)
			if c["name"] == c2["name"] and
			   c["domain"] == c2["domain"] then
				table.foreach(c,function(n,_)
					c2[n] = c[n] or c2[n] -- fix shit
				end)
				match = 1
				return 1 -- exit loop
			end
			end)
		if match == 0 then
			-- add it to the c
			table.insert(t2,c)
		end
	end)
end

-- WARING WARING  WARING WARING WARING WARING WARING WARING WARING WARING WARING
-- WARING WARING  WARING WARING WARING WARING WARING WARING WARING WARING WARING
--
-- begin of code taken from luasocket by Diego Nehab
-- this code is part of url.lua, released under the MIT license
--
-- WARING WARING  WARING WARING WARING WARING WARING WARING WARING WARING WARING
-- WARING WARING  WARING WARING WARING WARING WARING WARING WARING WARING WARING


-----------------------------------------------------------------------------
-- Parses a url and returns a table with all its parts according to RFC 2396
-- The following grammar describes the names given to the URL parts
-- <url> ::= <scheme>://<authority>/<path>;<params>?<query>#<fragment>
-- <authority> ::= <userinfo>@<host>:<port>
-- <userinfo> ::= <user>[:<password>]
-- <path> :: = {<segment>/}<segment>
-- Input
--   url: uniform resource locator of request
--   default: table with default values for each field
-- Returns
--   table with the following fields, where RFC naming conventions have
--   been preserved:
--     scheme, authority, userinfo, user, password, host, port,
--     path, params, query, fragment
-- Obs:
--   the leading '/' in {/<path>} is considered part of <path>
-----------------------------------------------------------------------------
function parse_url(url, default)
    -- initialize default parameters
    local parsed = {}
    for i,v in pairs(default or parsed) do parsed[i] = v end
    -- empty url is parsed to nil
    if not url or url == "" then return nil, "invalid url" end
    -- remove whitespace
    -- url = string.gsub(url, "%s", "")
    -- get fragment
    url = string.gsub(url, "#(.*)$", function(f)
        parsed.fragment = f
        return ""
    end)
    -- get scheme
    url = string.gsub(url, "^([%w][%w%+%-%.]*)%:",
        function(s) parsed.scheme = s; return "" end)
    -- get authority
    url = string.gsub(url, "^//([^/]*)", function(n)
        parsed.authority = n
        return ""
    end)
    -- get query stringing
    url = string.gsub(url, "%?(.*)", function(q)
        parsed.query = q
        return ""
    end)
    -- get params
    url = string.gsub(url, "%;(.*)", function(p)
        parsed.params = p
        return ""
    end)
    -- path is whatever was left
    if url ~= "" then parsed.path = url else parsed.path = '/' end
    local authority = parsed.authority
    if not authority then return parsed end
    authority = string.gsub(authority,"^([^@]*)@",
        function(u) parsed.userinfo = u; return "" end)
    authority = string.gsub(authority, ":([^:]*)$",
        function(p) parsed.port = p; return "" end)
    if authority ~= "" then parsed.host = authority end
    local userinfo = parsed.userinfo
    if not userinfo then return parsed end
    userinfo = string.gsub(userinfo, ":([^:]*)$",
        function(p) parsed.password = p; return "" end)
    parsed.user = userinfo
    return parsed
end


-- WARING WARING  WARING WARING WARING WARING WARING WARING WARING WARING WARING
-- WARING WARING  WARING WARING WARING WARING WARING WARING WARING WARING WARING
--
-- end of code taken from luasocket by Diego Nehab
-- this code is part of url.lua, released under the MIT license
--
-- WARING WARING  WARING WARING WARING WARING WARING WARING WARING WARING WARING
-- WARING WARING  WARING WARING WARING WARING WARING WARING WARING WARING WARING



-- returns the needed cookie for the domain...
-- returns the string
function get(t,res,domain,host)
	if domain == nil then
		error("cookie.get can't be called with an empty domain")
	end
      --print("cookie.get("..(res or"nil")..(domain or"nil")..(host or"nil"))
	local function domain_match(a,b)
		local x,_ = string.find(a,b)
		--print("Find: '"..a.."' '"..b.."' = "..tostring(x ~= nil))
		return x ~= nil
	end
	local r = {}
      --print(res,domain,host)
	table.foreach(t,function(_,c)
      --table.foreach(c,print)
		local l = Private.subpath_len(res,c["path"])
	      --print(Private.is_expired(c),l,c["domain"],c.host)
		if not Private.is_expired(c) and
		   l >= 0 and
		   (domain_match("."..domain,c["domain"]) or c.host == host)
			then
			--search if there is no othe cookie in r
			--with the same name
			local dup = false
			table.foreachi(r,function(_,v)
				if v.c.name == c.name then dup = true end
			end)
			if not dup then
				table.insert(r,{c=c,l=l})
			end
		end
	end)
	table.sort(r,function(a,b) return a.l > b.l end)
	local s = ""
	table.foreach(r,function(_,w)
                if w.c.name then
		        s = s .. "; " .. w.c.name .. "=" .. w.c.value
                end
	--	if w.c.domain then
	--		s = s .. '; $Domain = "' .. w.c.domain .. '"'
	--	end
	--	if w.c.path then
	--		s = s .. '; $Path = "' .. w.c.path .. '"'
	--	end
	end)
	if s ~= "" then
		--return '$Version = "1" ' .. s
		return string.sub(s,2)
	else
		return nil
	end
end

-- cleans expired cookies
function clean_expired(t)
	table.foreach(t,function(x,c)
	if Private.is_expired(c) then
		t[x] = nil
	end
	end)
end
