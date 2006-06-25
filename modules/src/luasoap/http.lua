-- this is not the origina http.lua, since it was luasocket-based
-- this file is released under the same license as LUA 5.0 (MIT)

MODULE_VERSION = "0.0.1"
MODULE_NAME = "http.lua"
MODULE_REQUIRE_VERSION = "0.0.99"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?file=http.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

require("browser") 
require("soap")

module("soap.http")

function call(browser, url, namespace, method, entries, headers)
	local rc, err = 
		browser:post_uri(url,
			soap.encode (namespace, method, entries, headers),
			{ "Content-type: text/xml", 
			  "SOAPAction: " .. method })
	if rc ~= nil then
		local ns, meth, ent = soap.decode(rc)
		return ns, meth, ent, nil
	else
		return nil, nil, nil, err
	end
end 

