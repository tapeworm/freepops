---
-- The browser object is the plugins interface to the web.
-- The object has the following methods:<BR/>
-- <BR/>
-- <B>get_uri(uri,exhed)</B> : returns string,err and takes the uri in 
-- "http://" form,exhed are extra header lines you want to add
-- , for example {"Range: bytes 0-100","User-agent: fake" }<BR/>
-- <BR/>
-- <B>get_head(uri,exhed)</B> : returns string,err and takes the uri in 
-- "http://" form,exhed are extra header lines you want to add. 
-- returns only the header, not the the body<BR/>
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
-- libero.lua for an example on how to use the callback.<BR>
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

--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--

dofile("cookie.lua")

-- the methods of a browser objects
local Private = {}

-- local functions
local Hidden = {}

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
		local _,_,x = string.find(v,capture)
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
		table.insert(head,"Cookie: "..cook)
	end
	if u.host ~= nil then
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
		local _,_,content = string.find(l,
			"^[Ss][Ee][Tt]%-[Cc][Oo][Oo][Kk][Ii][Ee]%s*:%s*(.*)")
		if content ~= nil then
			local c = cookie.parse_cookies(content,u.host)
			cookie.merge(self.cookies,c)
		end
	end)

end

-- gets the field Location: in a header table
function Hidden.get_location(gl_h)
	return table.foreach(gl_h,function(_,l)
		local _,_,location = string.find(l,
			"[Ll][Oo][Cc][Aa][Tt][Ii][Oo][Nn]%s*:%s*([^\r\n]*)")
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

-- reads the HTTP return code and returns
-- nil,error if an error
-- DONE,nil if ok
-- REDO,url if 3xx code
function Hidden.parse_header(self,gl_h)
	local _,_,ret = string.find(gl_h[1],"[^%s]+%s+(%d%d%d)")
	if ret == nil then
	
	end
	
	-- HTTP 1xx
	if string.byte(ret,1) == string.byte("1",1) then
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
		return Hidden.parse_header(self,gl_h1)
	-- HTTP 2xx
	elseif string.byte(ret,1) == string.byte("2",1) then
		return Hidden.DONE,nil
	-- HTTP 3xx
	elseif string.byte(ret,1) == string.byte("3",1) then
		if ret=="300" or ret=="304" or ret=="305" then
			return Hidden.error("Unsupported HTTP "..ret.." code")
		end
		if ret=="301" or ret=="302" or ret=="303" or ret=="307"  then
			local l = Hidden.get_location(gl_h)
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
	-- the callbacks
	if type(gl_b) == "table" then
		self.curl:setopt(curl.OPT_WRITEFUNCTION,Hidden.build_w_cb(gl_b))
	elseif type(gl_b) == "function" then
		self.curl:setopt(curl.OPT_WRITEFUNCTION,gl_b)
	else
		error("Hidden.perform must be called with table/function gl_b"..
			", but is called with a "..type(gl_b))		
	end
	self.curl:setopt(curl.OPT_HEADERFUNCTION,Hidden.build_w_cb(gl_h))
	local rc,err = self.curl:perform()

	-- check result
	if rc == 0 then
		Hidden.cookie_and_referer(self,url,gl_h)
		return Hidden.parse_header(self,gl_h)
	else
		return nil,err
	end

end

-- to not do by hand the call if we get a 3xx code
function Hidden.continue_or_return(rc,err,t,f,...)
	if rc == Hidden.DONE then
		return table.concat(t),nil
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
	if string.byte(loc,1) == string.byte("/",1) then
		local u = cookie.parse_url(self.referrer)
		return u.scheme .. "://" .. u.host .. ":" .. 
			(u.port or "80") .. loc
	else
		return loc
	end
end

--<==========================================================================>--

function Private.get_uri(self,url,exhed)
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_HTTPGET,1)
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,gl_b)

	return Hidden.continue_or_return(rc,err,gl_b,
		Private.get_uri,self,Hidden.mangle_location(self,err),exhed)
end

function Private.post_uri(self,url,post,exhed)
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_POST,1)
	self.curl:setopt(curl.OPT_POSTFIELDS,post)
	
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

function Private.get_head(self,url,exhed)
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_HTTPGET,1)
	self.curl:setopt(curl.OPT_NOBODY,1)
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,gl_b)

	self.curl:setopt(curl.OPT_NOBODY,0)

	return Hidden.continue_or_return(rc,err,gl_h,
		Private.get_head,self,Hidden.mangle_location(self,err),exhed)
end

function Private.pipe_uri(self,url,cb,exhed) 
	local gl_b,gl_h = {},{}
	
	self.curl:setopt(curl.OPT_HTTPGET,1)
	
	Hidden.build_header(self,url,exhed)
	
	local rc,err = Hidden.perform(self,url,gl_h,cb)

	return Hidden.continue_or_return(rc,err,{""},
		Private.pipe_uri,self,err,exhed)
end

function Private.show(self)
	print("browser:\n\tcookies:")
	table.foreach(self.cookies,function(_,c)
		table.foreach(c,function(a,b) print("\t\t"..a.."="..b) end)
		print("\n")
	end)
	print("\treferrer:\n\t\t" .. (self.referrer or ""))
	print("\tproxy:\n\t\t" .. (self.proxy or ""))
	print("\tproxyauth:\n\t\t" .. (self.proxyauth or ""))
	print("\tuseragent:\n\t\t" .. (self.useragent or ""))
end

function Private.init_curl(self)
	self.curl = curl.easy_init()

	-- to debug
	--self.curl:setopt(curl.OPT_VERBOSE,1)
	
	-- go!
	self.curl:setopt(curl.OPT_USERAGENT,self.useragent or 
		"cURL/browser.lua (;;;;) FreePOPs")
	if self.proxy ~= nil then
		self.curl:setopt(curl.OPT_PROXY,self.proxy)
		-- old cURL < 7.10.0 ?? have no OPT_PROXYTYPE
		if curl.OPT_PROXYTYPE ~= nil then 
			self.curl:setopt(curl.OPT_PROXYTYPE,curl.PROXY_HTTP)
		end
	end
	if self.proxyauth ~= nil then
		self.curl:setopt(curl.OPT_PROXYUSERPWD,self.proxyauth)
		-- old cURL < 7.10.7 have no OPT_PROXYAUTH
		if curl.OPT_PROXYAUTH ~= nil then
			self.curl:setopt(curl.OPT_PROXYAUTH,curl.AUTH_BASIC)
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

function Private.wherearewe(self)
	local u = cookie.parse_url(self.referrer)
	if u.port ~= nil then
		return u.host..":".. u.port
	else
		return u.host
	end
end

browser = {}

--<==========================================================================>--

---
-- Creates a new object.
-- @return object.
function browser.new()
	local b = {
		cookies = {},
		referrer = false, --nil will break the metatable check
		curl = false,
		proxy = os.getenv("LUA_HTTP_PROXY"),
		proxyauth = os.getenv("LUA_HTTP_PROXYAUTH"),
		useragent = os.getenv("LUA_HTTP_USERAGENT"),
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


