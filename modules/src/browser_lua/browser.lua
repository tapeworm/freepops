---
-- The browser object is the plugins interface to the web.
-- The object has the following methods:<BR/>
-- <BR/>
-- <B>get_uri(uri,exhed)</B> : returns string,err and takes the uri in 
-- "http://" form,exhed are extra header lines you want to add
-- , for example {["range"] = "0-100",["user-agent"] = "fake" }<BR/>
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
-- libero.lua for an example on how to use the callback. See 
-- <A HREF="http://www.tecgraf.puc-rio.br/~diego/luasocket/new/http.html">
-- this</A> for more info on the http-header table.<BR>
-- <BR/>
-- <B>show()</B> : Debug printing on the browser content.<BR/>


dofile("cookie.lua")

local Private = {}

function Private.build_w_cb(t)
        return function(s,len)
                -- stores the received data in the table t
                table.insert(t,s)
                -- return number_of_byte_served, error_message
                -- number_of_byte_served ~= string.len(s) is an error
                return len,nil
        end
end

function Private.get_uri(self,url,exhed) 
	local u = cookie.parse_url(url)

	--clean expired cookies
	cookie.clean_expired(self.cookies)

	-- the header
	local head = exhed or {}
	local cook = cookie.get(self.cookies,u.path,u.host,u.host)
	
	if self.referrer then
		table.insert(head,"Referer: "..self.referrer)
	end
	if cook ~= nil then
		table.insert(head,"Cookie: "..cook)
	end
	self.curl:setopt(curl.OPT_HTTPHEADER,head)
	
	--the url
	self.curl:setopt(curl.OPT_URL,url)
	
	-- the callbacks
	local gl_b,gl_h = {},{}
	self.curl:setopt(curl.OPT_WRITEFUNCTION,Private.build_w_cb(gl_b))
	self.curl:setopt(curl.OPT_HEADERFUNCTION,Private.build_w_cb(gl_h))

	-- go
	local rc,err = self.curl:perform()

	-- check result
	if rc == 0 then
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
		return table.concat(gl_b),nil
	else
		return nil,err
	end
end

function Private.pipe_uri(self,url,cb,exhed) 
	local u = cookie.parse_url(url)

	--clean expired cookies
	cookie.clean_expired(self.cookies)

	-- the header
	local head = exhed or {}
	local cook = cookie.get(self.cookies,u.path,u.host,u.host)
	
	if self.referrer then
		table.insert(head,"Referer: "..self.referrer)
	end
	if cook ~= nil then
		table.insert(head,"Cookie: "..cook)
	end
	self.curl:setopt(curl.OPT_HTTPHEADER,head)
	
	--the url
	self.curl:setopt(curl.OPT_URL,url)
	
	-- the callbacks
	local gl_b,gl_h = {},{}
	self.curl:setopt(curl.OPT_WRITEFUNCTION,cb)
	self.curl:setopt(curl.OPT_HEADERFUNCTION,Private.build_w_cb(gl_h))

	-- go
	local rc,err = self.curl:perform()

	-- check result
	if rc == 0 then
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
		return "",nil
	else
		return nil,err
	end
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
		--self.curl:setopt(curl.OPT_PROXYTYPE,curl.PROXY_HTTP)
	end
	if self.proxyauth ~= nil then
		self.curl:setopt(curl.OPT_PROXYUSERPWD,self.proxyauth)
		--self.curl:setopt(curl.OPT_PROXYAUTH,curl.AUTH_ANY)
	end
	-- tells the library to follow any Location:
        -- header that the server sends as part of an HTTP header
	self.curl:setopt(curl.OPT_FOLLOWLOCATION,1)
	-- libcurl will automatically set the Referer: field 
	-- in requests  where  it follows a Location: redirect
	self.curl:setopt(curl.OPT_AUTOREFERER,1)

end

function Private.serialize(self,name)
	local s = {}
	table.insert(s,name..".cookies="..serial.serialize(nil,self.cookies))
	table.insert(s,name..".referrer="..serial.serialize(nil,self.referrer))
	return name .. "= browser.new();" .. table.concat(s)
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


