---
-- The browser object is the plugins interface to the web.
-- The object has the following methods:<BR/>
-- <BR/>
-- <B>get_uri(uri,exhed)</B> : returns string,err and takes the uri in 
-- "http://" form,exhed are extra header lines you want to add
-- , for example {"Range: bytes 0-100","User-agent: fake" }<BR/>
-- <BR/>
-- <B>get_head(uri,exhed,fallback)</B> : returns string,err and takes 
-- the uri in 
-- "http://" form,exhed are extra header lines you want to add. 
-- returns only the header, not the the body. If fallback is true then
-- a GET with range: bytes 0 is tryed<BR/>
-- <BR/>
-- <B>get_head_and_body(uri,exhed,fallback)</B> : returns string,string,err and
-- takes the same arguments of get_uri, but returns as the first value the
-- header
-- <BR/>
-- <B>pipe_uri(uri,callback,exhed)</B> : 
-- Gets the uri and uses callback on the data
-- received,exhed  are extra header lines you want to add. <BR> 
-- The callback takes a string (the data) argument and returns a couple. 
-- The first argument is the amount of byte served, if ~= from the sring.len 
-- of the argument it is considered an error, and an error message.<BR/>
-- pipe_uri returns a string that is nil 
-- on error, "" on end of transmission. 
-- It also return an error if one.<BR>
-- See
-- libero.lua for an example on how to use the callback.<BR/>
-- <BR/>
-- <B>pipe_uri_with_header(self,url,cb_h,cb_b,exhed)</B> :
-- As pipe uri, but uses cb_h for the header and cb_b fpor the body.<BR/>
-- Since the browser module doesn't know the result of the GET it 
-- will not follow redirects. The mimer module uses this.<BR/>
-- <BR/>
-- <B>post_uri(uri,post,exhed)</B> : returns string,err and takes the uri in 
-- "http://" form, the post data in "name=val&..." form 
-- (you may need to urlescape it by hand), exhed<BR/>
-- <BR/>
-- <B>show()</B> : Debug printing on the browser content.<BR/>
-- <BR/>
-- <B>whathaveweread()</B> : returns the page's url we have returned 
-- (may differ from the requested if we got a redirect).<BR/>
-- <BR/>
-- <B>wherearewe()</B> :  returns the host we have contacted
-- (may differ from the requested if we got a redirect).<BR/>
-- <BR/>
-- <B>add_cookie(url,c)</B> :adds cookie c as if received browsing
-- url<BR/>
-- <BR/>
-- <B>get_cookie(name)</B> :returns the table containing all cookie 
-- attributes. Since the returned table is the same table the browser uses
-- (ie, passed by references) be careful. If you modify its values the
-- browser eill be affected too.
-- url<BR/>
-- <BR/>
-- <B>verbose_mode()</B> : activates the verbose logging of CURL<BR/>
-- <BR/>
-- <B>ssl_init_stuff()</B> : some stuff for SSL<BR/>
--<BR/>

MODULE_VERSION = "0.1.0"
MODULE_NAME = "browser.browser"
MODULE_REQUIRE_VERSION = "0.0.99"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=browser.browser.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

require("curl")
local cookie = require("browser.cookie")

-- the methods of a browser objects
local Private = {}

-- local functions
local Hidden = {}

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--


--<==========================================================================>--

Hidden.errors = {
	["400"] = "Bad Request",
	["401"] = "Unauthorized",
	["402"] = "Payment Required",
	["403"] = "Forbidden",
	["404"] = "Not Found",
	["405"] = "Method Not Allowed",
	["406"] = "Not Acceptable",
	["407"] = "Proxy Authentication Required",
	["408"] = "Request Timeout",
	["409"] = "Conflict",
	["410"] = "Gone",
	["411"] = "Length Required",
	["412"] = "Precondition Failed",
	["413"] = "Request Entity Too Large",
	["414"] = "Request-URI Too Long",
	["415"] = "Unsupported Media Type",
	["416"] = "Requested Range Not Satisfiable",
	["417"] = "Expectation Failed",
	["500"] = "Internal Server Error",
	["501"] = "Not Implemented",
	["502"] = "Bad Gateway",
	["503"] = "Service Unavailable",
	["504"] = "Gateway Timeout",
	["505"] = "HTTP Version Not Supported",
}

Hidden.DONE = 0
Hidden.REDO = 1

-- create a callback that stores in t
function Hidden.build_w_cb(t)
        return function(s,len)
                -- stores the received data in the table t
                table.insert(t,s)
                -- return number_of_byte_served, error_message
                -- number_of_byte_served ~= string.len(s) is an error
                return len,nil
        end
end

-- finds in a table t like {"Referer: xxx","Cookie: yyy"} if a field starts
-- with s and return the whole field or nil
function Hidden.find_in_header(t,s)
	local capture = "^("..s..")"
	return table.foreachi(t,function (k,v) 
		local x = string.match(v,capture)
		if x ~= nil then
			return v
		end
	end)
end

-- prepares the header with cookies and referer and host
function Hidden.build_header(self,url,exhed)
	local u = cookie.parse_url(url)

	--clean expired cookies
	cookie.clean_expired(self.cookies)

	-- the header
	local head = exhed or {}
	
	local cook = cookie.get(self.cookies,u.path,u.host,u.host)
	
	if self.referrer then
		local tmp = Hidden.find_in_header(head,"Referer:")
		if tmp == nil then
			table.insert(head,"Referer: "..self.referrer)
		end
	end
        if cook ~= nil then
           -- the excite website adds "\r\n" to the cookies...
           if string.find(cook,"\r\n$") then cook =string.sub(cook,1,-3) end
           table.insert(head,"Cookie: "..cook)
        end
	if u.host ~= nil then
		-- This is a terrible hack.  I had to put it so that hotmail would work.  The
		-- grammar that hotmail uses differs from the one described in cookie.lua.
		--
		if (string.find(u.host, "hotmail") ~= nil) then
			u.host = string.gsub(u.host, "%?.*$", "")
		end
		table.insert(head,"Host: "..u.host)
	end
	self.curl:setopt(curl.OPT_HTTPHEADER,head)
	
	--the url
	self.curl:setopt(curl.OPT_URL,url)
	
end

-- parses the response header updating the referer and cookies
function Hidden.cookie_and_referer(self,url,gl_h)
	local u = cookie.parse_url(url)
	-- save referrer
	self.referrer = url

	table.foreach(gl_h,function(_,l)
		local content = string.match(l,
			"^[Ss][Ee][Tt]%-[Cc][Oo][Oo][Kk][Ii][Ee]%s*:%s*(.*)")
		if content ~= nil then
			local c = cookie.parse_cookies(content,u.host)
			cookie.merge(self.cookies,c)
		end
	end)

end

-- adds dirname(u.path) .. / .. location if needed
function Hidden.adjust_path(l,u,location)
	local function clean_2_slash(s)
		return (string.gsub(s,"//","/"))
	end
	local function dirname(path)
		local base = ""
		if string.sub(path, -1, -1) == "/" then
			-- is a dir, so the dirname is the whole path
			if (string.sub(path, 1, 1) ~= "/") then
				base = "/" .. path
			else 
				base = path
			end
		else
			local rc = {}
			string.gsub(path,"([^/]+)",
				function(s)table.insert(rc,s)
			end)
			-- delete last element
			table.remove(rc,table.getn(rc))
			base = "/" .. table.concat(rc,"/") .. "/"
		end
		return clean_2_slash(base)
	end

	local u_dir = dirname(u.path)
	local l_dir = dirname(l.path)

	if (l_dir == "/") then 
		return clean_2_slash(u_dir .. location)
	else
		local x,y = string.find(u_dir,l_dir)
		if ( x == nil or y ~= string.len(u_dir)) then
			-- the l_dir path is not included in the u_dir, so
			-- we keep it untouched
			return clean_2_slash("/" .. location)
		else
			return clean_2_slash(
				string.sub(u_dir,1,x) .. "/" .. location)
		end
	end
	
end

-- gets the field Location: in a header table
function Hidden.get_location(gl_h,url)
	return table.foreach(gl_h,function(_,l)
		local location = string.match(l,
			"[Ll][Oo][Cc][Aa][Tt][Ii][Oo][Nn]%s*:%s*([^\r\n]*)")
		if location ~= nil then
			-- ah ah ah, what do you think? the RFC says that
			-- Location wants an absolute uri, but the 
			-- wounderful IIS sends a relative uri
			local l = cookie.parse_url(location)
			if ( l.host == nil or l.scheme == nil) then
				local u = cookie.parse_url(url)
				if ( u.host == nil or u.scheme == nil) then
					error("get_location must be called "..
						"with an absolute uri")
				end
				location = Hidden.adjust_path(l,u,location)
				if (l.host == nil) then
					location = u.host .. location
				end
				if (l.scheme == nil) then
					location = u.scheme .. "://"..location
				end
				l = cookie.parse_url(location)
				if ( l.host == nil or l.scheme == nil) then
					error("unable to recover bad Location")
				end
			end
		end
		return location
	end)
end

-- gets the field Refresh:'s URL in a header table
function Hidden.get_refresh_location(gl_h)
	return table.foreach(gl_h,function(_,l)
		local location = string.match(l,
			"[Rr][Ee][Ff][Rr][Ee][Ss][Hh]%s*:%s*[%d]+;[Uu][Rr][Ll]=([^\r\n]*)")
		return location
	end)
end

-- returns an error
function Hidden.error(s)
	log.say(s)
	return nil,s
end

-- error
function Hidden.errorcode(ret)
	return nil,(ret .. ": " .. (Hidden.errors[ret] or "unknown error"))
end

-- HTTP CONNECT Proxy 2xx
function Hidden.is_https_proxy_tunnel(b, url, ret)
	return (b.proxy ~= nil) and 
		(string.sub(url, 1, 5) == "https") and 
		(ret == "200")
end
	

-- reads the HTTP return code and returns
-- nil,error if an error
-- DONE,nil if ok
-- REDO,url if 3xx code
function Hidden.parse_header(self,gl_h,url)
	if gl_h[1] == nil then
		return Hidden.error("malformed HTTP header line: nil")
	end
	local ret = string.match(gl_h[1],"[^%s]+%s+(%d%d%d)")
	if ret == nil then
		--print("STRANGE HEADER!")
		table.foreach(gl_h,print)
		return Hidden.error("malformed HTTP header line: "..gl_h[1])
	end
        -- HTTP 1xx or HTTPS proxy tunnel
        if string.byte(ret,1) == string.byte("1",1) or
                Hidden.is_https_proxy_tunnel(self, url, ret) then
                local gl_h1 = {} -- to not lose the real header
                local end_of_1xx = false
                for i=1,table.getn(gl_h) do
                       if end_of_1xx then
                             table.insert(gl_h1,gl_h[i])
                       end
                       if gl_h[i] == "\r\n" then
                             end_of_1xx = true
                       end
                end
                if gl_h1[1] ~= nil then
                       return Hidden.parse_header(self,gl_h1,url)
                --else
                       --return Hidden.error("Malformed HTTP/1.x 1xx header")
                end
        end
	-- HTTP 2xx
	if string.byte(ret,1) == string.byte("2",1) then
		if self.followRefreshHeader == true then
			local l = Hidden.get_refresh_location(gl_h)
			if l ~= nil then
				return Hidden.REDO,l
			end
		end
		return Hidden.DONE,nil
	-- HTTP 3xx
	elseif string.byte(ret,1) == string.byte("3",1) then
		if ret=="300" or ret=="304" or ret=="305" then
			return Hidden.error("Unsupported HTTP "..ret.." code")
		end
		if ret=="301" or ret=="302" or ret=="303" or ret=="307"  then
			local l = Hidden.get_location(gl_h,url)
			if l ~= nil then
				return Hidden.REDO,l
			else
				return Hidden.error("Unable to find Location:")
			end
		end
	-- HTTP 4xx
	elseif string.byte(ret,1) == string.byte("4",1) then
		return Hidden.errorcode(ret)
	-- HTTP 5xx
	elseif string.byte(ret,1) == string.byte("5",1) then
		return Hidden.errorcode(ret)
	else
		return Hidden.error("Unsupported HTTP "..ret.." code")
	end
end

-- starts curl!
function Hidden.perform(self,url,gl_h,gl_b)
	-- the callback for the body
	if type(gl_b) == "table" then
		self.curl:setopt(curl.OPT_WRITEFUNCTION,Hidden.build_w_cb(gl_b))
	elseif type(gl_b) == "function" then
		self.curl:setopt(curl.OPT_WRITEFUNCTION,gl_b)
	else
		error("Hidden.perform must be called with table/function gl_b"..
			", but is called with a "..type(gl_b))		
	end
	-- the callback for the header
	if type(gl_h) == "table" then
		self.curl:setopt(
			curl.OPT_HEADERFUNCTION,Hidden.build_w_cb(gl_h))
	elseif type(gl_h) == "function" then
		self.curl:setopt(curl.OPT_HEADERFUNCTION,gl_h)
	else
		error("Hidden.perform must be called with table/function gl_h"..
			", but is called with a "..type(gl_h))		
	end

	local rc,err = self.curl:perform()

	-- check result
	if rc == 0 then
		if type(gl_h) == "function" then
			-- we haven *not* the header!
			return rc,err
		else
			Hidden.cookie_and_referer(self,url,gl_h)
			return Hidden.parse_header(self,gl_h,url)
		end
	else
		return nil,err
	end

end

-- return true if the table contains strings (checks only the first argument)
function Hidden.is_a_string_table(t)
	if type(t[1]) == "string" then
		return true
	else
		return false
	end
end

-- to not do by hand the call if we get a 3xx code
function Hidden.continue_or_return(rc,err,t,f,...)
	if rc == Hidden.DONE then
		if type(t) == "table" then
			if Hidden.is_a_string_table(t) then
				return table.concat(t),nil
			else
				-- we are in the case of the get_head_and_body
				return 
					table.concat(t[1] or {}),
					table.concat(t[2] or {}),nil
			end
		else
			error("Hidden.continue_or_return(_,_,t,...): "..
				"t of invalit type")
		end
	elseif rc == Hidden.REDO then
		return f(unpack(arg))
	elseif rc == nil then
		return nil,err
	else
		error("Hidden.perform returned something strange")
	end
end

-- to handle local redirect
function Hidden.mangle_location(self,loc)
	if loc == nil then return nil end
	-- some shit has a not RFC compliant header
	local x = string.find(loc,"^[Hh/]")
	if x == nil then 
		-- ok, this cookie is rotten
		-- we have to add the whole "http://host/path/"
		local part_path = nil
		local u = cookie.parse_url(self.referrer)
		if u ~= nil then
	                part_path = string.match(u.path or "/","(.*/)")
		end
                loc = (part_path or "/") .. loc
	end
	-- now find where we have to go!
	if string.byte(loc,1) == string.byte("/",1) then
		local u = cookie.parse_url(self.referrer)
		if u ~= nil then
			loc = u.scheme .. "://" .. u.host .. ":" .. 
				(u.port or "80") .. loc
		end
	end	
	return loc
end

--<==========================================================================>--

function Private.get_uri(self,url,exhed)
	assert(url ~= nil,"get_uri can't be called on a nil uri")
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_HTTPGET,1)
	self.curl:setopt(curl.OPT_CUSTOMREQUEST,"GET")
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,gl_b)

	return Hidden.continue_or_return(rc,err,gl_b,
		Private.get_uri,self,Hidden.mangle_location(self,err),exhed)
end

function Private.get_head_and_body(self,url,exhed)
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_HTTPGET,1)
	self.curl:setopt(curl.OPT_CUSTOMREQUEST,"GET")
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,gl_b)

	return Hidden.continue_or_return(rc,err,{gl_h,gl_b},
		Private.get_uri,self,Hidden.mangle_location(self,err),exhed)
end

function Private.custom_get_uri(self,url,custom,exhed)
	assert(url ~= nil,"custom_get_uri can't be called on a nil uri")
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_CUSTOMREQUEST,custom)
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,gl_b)

	return Hidden.continue_or_return(rc,err,gl_b,
		Private.get_uri,self,Hidden.mangle_location(self,err),exhed)
end

function Private.custom_post_uri(self,url,custom,post,exhed)
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_POST,1)
	self.curl:setopt(curl.OPT_POSTFIELDS,post)
	self.curl:setopt(curl.OPT_CUSTOMREQUEST,custom)
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,gl_b)
	
	return Hidden.continue_or_return(rc,err,gl_b,
		--Private.post_uri,self,Hidden.mangle_location(self,err),post,exhed)
		Private.get_uri,self,Hidden.mangle_location(self,err),exhed)
end

function Private.post_uri(self,url,post,exhed)
	assert(url ~= nil,"post_uri can't be called on a nil uri")
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_POST,1)
	self.curl:setopt(curl.OPT_POSTFIELDS,post)
	self.curl:setopt(curl.OPT_CUSTOMREQUEST,"POST")
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,gl_b)
	
	return Hidden.continue_or_return(rc,err,gl_b,
		--Private.post_uri,self,Hidden.mangle_location(self,err),post,exhed)
		Private.get_uri,self,Hidden.mangle_location(self,err),exhed)
end

function Private.add_cookie(self,url,c)
	local u = cookie.parse_url(url)
	local b = cookie.parse_cookies(c,u.host)
	cookie.merge(self.cookies,b)
end

function Private.get_cookie(self,name)
	return table.foreach(self.cookies,function(k,v)
			if v.name == name then
				return v
			end
		end)
end

function Private.get_head(self,url,exhed,fallback)
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_HTTPGET,1)
	self.curl:setopt(curl.OPT_CUSTOMREQUEST,"HEAD")
	self.curl:setopt(curl.OPT_NOBODY,1)
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,gl_b)
	
	self.curl:setopt(curl.OPT_NOBODY,0)

	-- since some server do not implement it we try the last thing
	if rc == nil and fallback then
		gl_b,gl_h = {},{}
		self.curl:setopt(curl.OPT_HTTPGET,1)
		self.curl:setopt(curl.OPT_CUSTOMREQUEST,"GET")
		Hidden.build_header(self,url,{"Range: bytes=0-1"})
		
		rc,err = Hidden.perform(self,url,gl_h,gl_b)
	end

	return Hidden.continue_or_return(rc,err,gl_h,
		Private.get_head,self,Hidden.mangle_location(self,err),exhed)
end

function Private.pipe_uri(self,url,cb,exhed) 
	local gl_h = {}
	
	self.curl:setopt(curl.OPT_HTTPGET,1)
	self.curl:setopt(curl.OPT_CUSTOMREQUEST,"GET")
	
	Hidden.build_header(self,url,exhed)
	local rc,err = Hidden.perform(self,url,gl_h,cb)

	return Hidden.continue_or_return(rc,err,{""},
		Private.pipe_uri,self,Hidden.mangle_location(self,err),
		cb,exhed)
end

function Private.pipe_uri_with_header(self,url,cb_h,cb_b,exhed) 
	
	self.curl:setopt(curl.OPT_HTTPGET,1)
	self.curl:setopt(curl.OPT_CUSTOMREQUEST,"GET")
	
	Hidden.build_header(self,url,exhed)
	local rc,err = Hidden.perform(self,url,cb_h,cb_b)

	return Hidden.continue_or_return(rc,err,{""},
		 Private.pipe_uri_with_header,self,
		 Hidden.mangle_location(self,err),cb_h,cb_b,exhed)
end

function Private.show(self)
	log.dbg("browser:\n\tcookies:")
	table.foreach(self.cookies,function(_,c)
		table.foreach(c,function(a,b) log.dbg("\t\t"..a.."="..b) end)
		log.dbg("\n")
	end)
	log.dbg("\treferrer:\n\t\t" .. (self.referrer or ""))
	log.dbg("\tproxy:\n\t\t" .. (self.proxy or ""))
	log.dbg("\tproxyauth:\n\t\t" .. (self.proxyauth or ""))
	log.dbg("\tuseragent:\n\t\t" .. (self.useragent or ""))
end

function Private.init_curl(self)
	self.curl = curl.easy_init()

	-- to debug
	--self.curl:setopt(curl.OPT_VERBOSE,1)
	
	-- useragent 
	self.curl:setopt(curl.OPT_USERAGENT,self.useragent or 
		"cURL/browser.lua (;;;;) FreePOPs")

	-- proxy
	if self.proxy ~= nil then
		self.curl:setopt(curl.OPT_PROXY,self.proxy)
		-- old cURL < 7.10.0 ?? have no OPT_PROXYTYPE
		if curl.OPT_PROXYTYPE ~= nil then 
			self.curl:setopt(curl.OPT_PROXYTYPE,curl.PROXY_HTTP)
		end
	end

	-- init the proxy authentication stuff 
	-- some functions to make the code more readable
	local function init_generic_proxy()
		if browser.ssl_enabled() then
			self.curl:setopt(curl.OPT_PROXYAUTH,
				curl.AUTH_BASIC + curl.AUTH_NTLM + 
				curl.AUTH_GSSNEGOTIATE + 
				curl.AUTH_DIGEST)
		else
			self.curl:setopt(curl.OPT_PROXYAUTH,
				curl.AUTH_BASIC)
		end
	end

	local fpat_2_curl = {
		["gss"] = curl.AUTH_GSSNEGOTIATE,
		["ntlm"] = curl.AUTH_NTLM,
		["digest"] = curl.AUTH_DIGEST,
		["basic"] = curl.AUTH_BASIC,
	}

	local function init_specific_proxy(at)
		local a = fpat_2_curl[at]
		if a ~= nil then
			self.curl:setopt(curl.OPT_PROXYAUTH,a)
		else
			log.error_print("Internal error, invalid fpat " .. at)
		end
	end
	
	if self.proxyauth ~= nil then
		self.curl:setopt(curl.OPT_PROXYUSERPWD,self.proxyauth)
		-- old cURL < 7.10.7 have no OPT_PROXYAUTH
		if curl.OPT_PROXYAUTH ~= nil then
			if self.fpat ~= nil then
				init_specific_proxy(self.fpat)
			else
				init_generic_proxy()
			end
		end
	end
	
	-- tells the library to follow any Location:
        -- header that the server sends as part of an HTTP header
	self.curl:setopt(curl.OPT_FOLLOWLOCATION,0)
end

function Private.serialize(self,name)
	local s = {}
	table.insert(s,name..".cookies="..serial.serialize(nil,self.cookies))
	table.insert(s,name..".referrer="..serial.serialize(nil,self.referrer))
	return name .. "= browser.new();" .. table.concat(s)
end

function Private.whathaveweread(self)
	return self.referrer
end

function Private.setFollowRefreshHeader(self, val)
	self.followRefreshHeader = val
end

function Private.wherearewe(self)
	local u = cookie.parse_url(self.referrer)
	if u.port ~= nil then
		return u.host..":".. u.port
	else
		return u.host
	end
end

function Private.ssl_init_stuff(self)
	self.curl:setopt(curl.OPT_SSL_VERIFYHOST,  2)
	self.curl:setopt(curl.OPT_SSL_VERIFYPEER, 0)
end

function Private.verbose_mode(self)
	self.curl:setopt(curl.OPT_VERBOSE,1)
end


--<==========================================================================>--

module("browser",package.seeall)

---
-- Creates a new object.
-- @return object.
function new(override_useragent)
	local b = {
		cookies = {},
		referrer = false, --nil will break the metatable check
		curl = false,
		proxy = os.getenv("LUA_HTTP_PROXY"),
		proxyauth = os.getenv("LUA_HTTP_PROXYAUTH"),
		useragent = override_useragent or 
		  os.getenv("LUA_HTTP_USERAGENT"),
		fpat = os.getenv("LUA_FORCE_PROXY_AUTH_TYPE"),
		followRefreshHeader = false,
	}

	setmetatable(b,{
		__index = Private,
		__newindex = function(t,k,v) 
			log.error_abort("No allowed to create a new field "..
				"in a browser object!")
		end
	})

	b:init_curl()
	
	-- see what we have done
	--b:show()
	
	return b
end

---
-- Returns true if the browser is SSL enabled.
-- @return boolean.
function ssl_enabled()
	local s = curl.version()
	local x = string.match(s,"([SsTt][SsLl][LlSs])")
	return x ~= nil
end

