--<==========================================================================>--
--<=                    FREEPOPS CONFIGURATION FILE                         =>--
--<==========================================================================>--

-- Here we have 3 sections:
--    1) mail-domains -> module binding
--    2) accept/reject policy
--    3) paths for .lua/.so files

-- -------------------------------------------------------------------------- --
-- 1) Map for domains -> modules
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
freepops.MODULES_MAP["virgilio.it"]	= {
	name="tin.lua",
	args={folder="INBOX"}
}

freepops.MODULES_MAP["tin.it"]		= {
	name="tin.lua",
	args={folder="INBOX"}
}

-- lycos
freepops.MODULES_MAP["lycos.co.uk"]	= {name="davmail.lua"}
freepops.MODULES_MAP["lycos.ch"]	= {name="davmail.lua"}
freepops.MODULES_MAP["lycos.de"]	= {name="davmail.lua"}
freepops.MODULES_MAP["lycos.es"]	= {name="davmail.lua"}
freepops.MODULES_MAP["lycos.it"]	= {name="davmail.lua"}
freepops.MODULES_MAP["lycos.at"]	= {name="davmail.lua"}
freepops.MODULES_MAP["lycos.nl"]	= {name="davmail.lua"}
freepops.MODULES_MAP["spray.se"]	= {name="davmail.lua"}

-- gmail
freepops.MODULES_MAP["gmail.com"]	= {name="gmail.lua"}

-- yahoo
freepops.MODULES_MAP["yahoo.com"]	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.ar"]	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.it"]       	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.ca"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.co.in"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.tw"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.uk"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.cn"] 	= {name="yahoo.lua"}

-- hotmail
freepops.MODULES_MAP["hotmail.com"]	= {name="hotmail.lua"}
freepops.MODULES_MAP["hotmail.de"]	= {name="hotmail.lua"}
freepops.MODULES_MAP["hotmail.co.uk"]	= {name="hotmail.lua"}
freepops.MODULES_MAP["hotmail.co.jp"]	= {name="hotmail.lua"}
freepops.MODULES_MAP["msn.com"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["webtv.com"]	= {name="hotmail.lua"}
freepops.MODULES_MAP["charter.com"]	= {name="hotmail.lua"}
freepops.MODULES_MAP["compaq.net"]	= {name="hotmail.lua"}
freepops.MODULES_MAP["passport.com"]	= {name="hotmail.lua"}

-- aol
freepops.MODULES_MAP["aol.com"]		= {name="aol.lua"}
freepops.MODULES_MAP["aol.com.ar"]	= {name="aol.lua"}
freepops.MODULES_MAP["aol.fr"]		= {name="aol.lua"}
freepops.MODULES_MAP["aol.com.mx"]	= {name="aol.lua"}
freepops.MODULES_MAP["aol.com.au"]	= {name="aol.lua"}
freepops.MODULES_MAP["aol.de"]		= {name="aol.lua"}
freepops.MODULES_MAP["aol.com.pr"]	= {name="aol.lua"}
freepops.MODULES_MAP["aol.com.br"]	= {name="aol.lua"}
freepops.MODULES_MAP["jp.aol.com"]	= {name="aol.lua"}
freepops.MODULES_MAP["aol.com.uk"]	= {name="aol.lua"}
freepops.MODULES_MAP["aol.ca"]		= {name="aol.lua"}
freepops.MODULES_MAP["aola.com"]	= {name="aol.lua"}
freepops.MODULES_MAP["netscape.net"]    = {name="aol.lua"}

-- squirrelmail
freepops.MODULES_MAP["mydom.com"]	= {name="squirrelmail.lua"}

-- tre.it
freepops.MODULES_MAP["tre.it"]		= {name="tre.lua"}

-- supereva.it
freepops.MODULES_MAP["@supereva.it"]	= {name="supereva.lua"}
freepops.MODULES_MAP["@freemail.it"]	= {name="supereva.lua"}
freepops.MODULES_MAP["@freeweb.org"]	= {name="supereva.lua"}
freepops.MODULES_MAP["@mybox.it"]	= {name="supereva.lua"}
freepops.MODULES_MAP["@superdada.com"]	= {name="supereva.lua"}
freepops.MODULES_MAP["@cicciociccio.com"]= {name="supereva.lua"}
freepops.MODULES_MAP["@mp4.it"]		= {name="supereva.lua"}
freepops.MODULES_MAP["@dadacasa.com"]	= {name="supereva.lua"}

-- popforward plugin
--freepops.MODULES_MAP["something.xx"] 	= {
--	name="popforward.lua",
--	args={
--		port=110,
--		host="in.virgilio.it",
--		realusername="abcdef",
--		pipe={"/usr/bin/spamc","-t","5"}, -- "/usr/bin/spamc -t 5",
--		pipe_limit=0, -- 0 unlimited, numer of octects of biggest piped
--	}
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

freepops.MODULES_MAP["kerneltrap.org"] 	= {
	name="aggregator.lua",
	args={host="http://kerneltrap.org/node/feed"}
}

freepops.MODULES_MAP["linux.kerneltrap.org"] 	= {
	name="aggregator.lua",
	args={host="http://kerneltrap.org/taxonomy/feed/or/2,37,13,19"}
}

freepops.MODULES_MAP["mozillaitalia.org"] 	= {
	name="aggregator.lua",
	args={host="http://www.mozillaitalia.org/feed/"}
}

freepops.MODULES_MAP["linuxgazette.net"] 	= {
	name="aggregator.lua",
	args={host="http://linuxgazette.net/lg.rss"}
}

-- -------------------------------------------------------------------------- --
-- 2) Policy
--
-- Here you tell freepops which email addresses are accepted and which rejected
-- Consider that if the address fits the accepted list it is accepted even if  
-- would fit the reject list.
--
-- Note that the expressions should match the full line but not contain the 
-- ^ or $ delimiters. Lua string matching facility is used and the capture 
-- created will be "^(" .. your expression here .. ")$". nil capture means not
-- matched.
--


freepops.ACCEPTED_ADDRESSES = {
	-- empty table means that there is no address that is accepted
	-- without looking at the rejected list

	-- "example@foo.xx" -- use this to allow this particular mail address
	-- ".*@foo.xx" -- accept everythig at the foo.xx domain
}

freepops.REJECTED_ADDRESSES = {
	-- empty table means to allow everybody

	-- "example@foo.xx" -- reject this guy
	-- ".*@foo.xx" -- reject the full foo.xx domain
}

-- -------------------------------------------------------------------------- --
-- 3) Customize here the paths for .lua and .so files
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
	
-- Really interesting for the geek user.
-- These paths are searched for unofficial plugins
freepops.MODULES_PREFIX_UNOFFICIAL = {
	os.getenv("FREEPOPSLUA_PATH_UNOFFICIAL") or "./",
	"./src/lua_unofficial",
	--os.getenv("FREEPOPSLUA_USER_UNOFFICIAL") or "./"
	}



--<==========================================================================>--

-- eof
