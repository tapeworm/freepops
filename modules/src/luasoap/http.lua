-- this is not the origina http.lua, since it was luasocket-based
-- this file is released under the same license as LUA 5.0 (MIT)

freepops.dofile("browser.lua") 
require "soap"
module("soap.http")

function call(browser, url, namespace, method, entries, headers)
	local rc, err = 
		browser:post_uri(url,
			soap.encode (namespace, method, entries, headers),
			{ "Content-type: text/xml", 
			  "SOAPAction: " .. method })
	if rc ~= nil then
		return soap.decode(rc), nil
	else
		return nil, err
	end
end 

