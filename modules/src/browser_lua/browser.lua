---
-- The browser object is the plugins interface to the web.
-- The object has the following methods:<BR/>
-- <BR/>
-- <B>get_uri(uri)</B> : returns string,err and takes the uri in 
-- "http://" form<BR/>
-- <BR/>
-- <B>pipe_uri(uri,callback)</B> : Gets the uri and uses callback on the data
-- received. <BR> The callback takes a string (the data) and an optional error 
-- message as arguments and returns a couple. 
-- The first argument is true if it is ok to continue, nil if not. 
-- The second an error message. <BR/>
-- pipe_uri returns a string that is nil 
-- on error, "" on end of transmission. 
-- It also return a table representing the http header returned.<BR>
-- See
-- libero.lua for an example on how to use the callback. See 
-- <A HREF="http://www.tecgraf.puc-rio.br/~diego/luasocket/new/http.html">
-- this</A> for more info on the http-header table.<BR>
-- <BR/>
-- <B>show()</B> : Debug printing on the browser content.<BR/>


dofile("cookie.lua")

local Private = {}

function Private.get_uri(self,uri) 
	local rc
	local u = socket.url.parse(uri)
	if not u.path then u.path = "/" end
	--table.foreach(u,print)
	local r = {url=uri,headers={referrer = self.referrer,
		cookie = cookie.get(self.cookies,u.path,u.host,u.host),
		["user-agent"] = self.USERAGENT}}
	--table.foreach(r,print)	
	--table.foreach(r.headers,print)
	
	rc = socket.http.request(r)
	if rc.code == 200 then
		cookie.merge(self.cookies,cookie.parse_cookies(
			rc.headers["set-cookie"],u.host))
		self.referrer=uri
		return rc.body,rc
	else
		return nil,rc
	end
end

function Private.pipe_uri(self,uri,cb) 
	local rc
	local u = socket.url.parse(uri)
	if not u.path then u.path = "/" end
	--table.foreach(u,print)
	local r = {url=uri,headers={referrer = self.referrer,
		cookie = cookie.get(self.cookies,u.path,u.host,u.host),
		["user-agent"] = self.USERAGENT}}
	--table.foreach(r,print)	
	--table.foreach(r.headers,print)
	rc = socket.http.request_cb(r,{body_cb=cb})
	if rc.code == 200 then
		cookie.merge(self.cookies,cookie.parse_cookies(
			rc.headers["set-cookie"],u.host))
		self.referrer=uri
		return "",rc
	else
		return nil,rc
	end

end

function Private.show(self)
	print("browser:\n\tcookies:")
	table.foreach(self.cookies,function(_,c)
		table.foreach(c,function(a,b) print("\t\t"..a.."="..b) end)
		print("\n")
	end)
	print("\treferrer:\n\t\t" .. (self.referrer or ""))
end

browser = {}

--<==========================================================================>--

---
-- Creates a new object.
-- @return object.
function browser.new()
	local proxy = os.getenv("LUA_HTTP_PROXY")
	local useragent = os.getenv("LUA_HTTP_USERAGENT")
		
	local b = {
	cookies = {},
	referrer = nil,
	get_uri = Private.get_uri,
	pipe_uri = Private.pipe_uri,
	show = Private.show,
	PROXY_HOST = nil,
	PROXY_PORT = nil,
	PROXY_AUTH = nil,
	MAX_TIMEOUT = nil,
	USERAGENT = nil,
	}

	-- proxy
	if proxy ~= nil then
		local _,_,h,p = string.find(proxy,"([%w_%-]+):(%d+)")
		p = p or 80
		if h ~= nil then
			b.PROXY_HOST = h
			b.PROXY_PORT = p

			socket.http.PROXY_HOST = h
			socket.http.PROXY_PORT = p
			end
	end
	
	--useragent
	b.USERAGENT = useragent
	socket.http.USERAGENT = useragent

	return b
end

---
-- Returns the function named f, the one you use when you write b:f().
-- @param f string the function name.
-- @return function.
function browser.getf(f)
	return Private[f]
end



--<========================>--

--[[
b = browser.new()
b.USERAGENT = "CIAO"
--b:show()
file,t = b:get_uri("http://localhost/ciao")
if file then
	print("got "..string.len(file))
end
b:show()

print("...............")
file,t = b:get_uri("http://liberopops.diludovico.it")
if file then
	print("got "..string.len(file))
end
b:show()
print("...............")
file,t = b:get_uri("http://tassi.web.cs.unibo.it")
if file then
	print("got "..string.len(file))
end
b:show()
print("...............")

file,t = b:get_uri("http://www.libero.it")
if file then
	print("got "..string.len(file))
end
b:show()
--]]
