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

-- this is the tutorial plugin...
freepops.MODULES_MAP["foo.xx"] 	= {name="foo.lua"}

-- libero plugin
freepops.MODULES_MAP["libero.it"] 	= {name="libero.lua"}
freepops.MODULES_MAP["iol.it"] 		= {name="libero.lua"}
freepops.MODULES_MAP["inwind.it"] 	= {name="libero.lua"}
freepops.MODULES_MAP["blu.it"] 		= {name="libero.lua"}

-- tin
freepops.MODULES_MAP["virgilio.it"]	= {name="tin.lua"}
freepops.MODULES_MAP["tin.it"]		= {name="tin.lua"}

-- lycos
freepops.MODULES_MAP["lycos.it"]	= {name="lycos.lua"}

-- gmail
freepops.MODULES_MAP["gmail.com"]	= {name="gmail.lua"}

-- popforward plugin
--freepops.MODULES_MAP["virgilio.it"] 	= {
--	name="popforward.lua",
--	args={port=110,host="in.virgilio.it"}
--}

-- kernel.org Changelog plugin
freepops.MODULES_MAP["kernel.org"] 	= {name="kernel.lua"}

freepops.MODULES_MAP["kernel.org.24"] 	= {
	name="kernel.lua",
	args={host="24"}
}
freepops.MODULES_MAP["kernel.org.26"] 	= {
	name="kernel.lua",
	args={host="26"}
}

-- flatnuke news plugin
freepops.MODULES_MAP["flatnuke"] 	= {
	name="flatnuke.lua"
}

-- flatnuke binded domains
freepops.MODULES_MAP["freepops.it"] 	= {
	name="flatnuke.lua",
	args={host="http://freepops.sourceforge.net/it"}
}

freepops.MODULES_MAP["freepops.en"] 	= {
	name="flatnuke.lua",
	args={host="http://freepops.sourceforge.net/en"}
}

-- rss backended news plugin
freepops.MODULES_MAP["aggregator"] 		= {
	name="aggregator.lua"
}

-- rss binded domains
freepops.MODULES_MAP["freepops.rss.en"] 	= {
	name="aggregator.lua",
	args={host="http://freepops.sf.net/en/misc/backend.rss"}
}

freepops.MODULES_MAP["freepops.rss.it"] 	= {
	name="aggregator.lua",
	args={host="http://freepops.sf.net/it/misc/backend.rss"}
}

freepops.MODULES_MAP["flatnuke.sf.net"] 	= {
	name="aggregator.lua",
	args={host="http://flatnuke.sf.net/misc/backend.rss"}
}

freepops.MODULES_MAP["ziobudda.net"] 	= {
	name="aggregator.lua",
	args={host="http://www.ziobudda.net/headlines/head.rdf"}
}

freepops.MODULES_MAP["punto-informatico.it"] 	= {
	name="aggregator.lua",
	args={host="http://punto-informatico.it/fader/pixml.xml"}
}

freepops.MODULES_MAP["linuxdevices.com"] 	= {
	name="aggregator.lua",
	args={host="http://www.linuxdevices.com/backend/headlines.rdf"}
}

freepops.MODULES_MAP["securityfocus.com"] 	= {
	name="aggregator.lua",
	args={host="http://www.securityfocus.com/rss/vulnerabilities.xml"}
}

freepops.MODULES_MAP["gaim.sf.net"] 	= {
	name="aggregator.lua",
	args={host="http://gaim.sourceforge.net/rss.php/news"}
}

freepops.MODULES_MAP["games.gamespot.com"] 	= {
	name="aggregator.lua",
	args={host="http://www.gamespot.com/misc/rss/gamespot_updates_all_games.xml"}
}

freepops.MODULES_MAP["news.gamespot.com"] 	= {
	name="aggregator.lua",
	args={host="http://www.gamespot.com/misc/rss/gamespot_updates_news.xml"}
}

-- -------------------------------------------------------------------------- --
-- Customize here the paths for .lua and .so files
--
-- Not really interesting for the user.
-- 
freepops.MODULES_PREFIX = {
	-- Culd this be a security hole? this VAR is set by FP, but ...
	-- ... I need to read more about environment ...
	os.getenv("FREEPOPSLUA_PATH") or "./",
	"./lua/",
	"./",
	"./src/lua/",
	"./modules/include/",
	"./modules/lib/"}

--<==========================================================================>--

-- eof
