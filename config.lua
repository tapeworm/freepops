--<==========================================================================>--
--<=                    FREEPOPS CONFIGURATION FILE                         =>--
--<==========================================================================>--

-- -------------------------------------------------------------------------- --
-- Map for domains -> modules
--
-- Here you tell freepops what plugin should be used for you mailaddress domain
-- Some plugins acceprs som args. see popforward as an example of arg 
-- passing plugin.
-- 

-- libero plugin
freepops.MODULES_MAP["libero.it"] 	= {name="libero.lua"}
freepops.MODULES_MAP["iol.it"] 		= {name="libero.lua"}
freepops.MODULES_MAP["inwind.it"] 	= {name="libero.lua"}
freepops.MODULES_MAP["blu.it"] 		= {name="libero.lua"}

-- popforward plugin
freepops.MODULES_MAP["virgilio.it"] 	= {name="popforward.lua",
					   args={port=110,
					         host="in.virgilio.it"}
					  }

freepops.MODULES_MAP["flatnuke"] 		= {name="flatnuke"}
-- -------------------------------------------------------------------------- --
-- Customize here the paths for .lua and .so files
--
-- Not really interesting for the user.
-- 
freepops.MODULES_PREFIX = {
	os.getenv("FREEPOPSLUA_PATH") or "./",
	"./lua/",
	"./",
	"./src/lua/",
	"./modules/include/",
	"./modules/lib/"}

--<==========================================================================>--
