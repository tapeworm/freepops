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
-- Some plugins accept some args. see popforward as an example of arg 
-- passing plugin. If the plugin has regex set to true then the mailaddress
-- will be considered a regexp.
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
freepops.MODULES_MAP["alice.it"]	= {
	name="tin.lua",
	args={folder="INBOX"}
}
freepops.MODULES_MAP["tim.it"]		= {
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
freepops.MODULES_MAP["jubii.dk"]	= {name="davmail.lua"}

-- gmail
freepops.MODULES_MAP["gmail.com"]	= {name="gmail.lua"}

-- yahoo
freepops.MODULES_MAP["yahoo.com"]	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.ar"]	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.it"]       	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.ca"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.co.in"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.tw"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.co.uk"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.cn"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.br"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.com.hk"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.es"] 	= {name="yahoo.lua"}
freepops.MODULES_MAP["yahoo.de"]        = {name="yahoo.lua"} 
freepops.MODULES_MAP["yahoo.dk"]        = {name="yahoo.lua"} 
freepops.MODULES_MAP["rocketmail.com"]  = {name="yahoo.lua"}
freepops.MODULES_MAP["talk21.com"]  = {name="yahoo.lua"}
 

-- hotmail
freepops.MODULES_MAP["hotmail.com"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["hotmail.de"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["hotmail.it"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["hotmail.co.uk"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["hotmail.co.jp"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["hotmail.fr"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["msn.com"]			= {name="hotmail.lua"}
freepops.MODULES_MAP["webtv.com"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["charter.com"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["compaq.net"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["passport.com"]		= {name="hotmail.lua"}
freepops.MODULES_MAP["messengeruser.com"]	= {name="hotmail.lua"}

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
freepops.MODULES_MAP["aol.co.uk"]	= {name="aol.lua"}
freepops.MODULES_MAP["aol.ca"]		= {name="aol.lua"}
freepops.MODULES_MAP["aola.com"]	= {name="aol.lua"}
freepops.MODULES_MAP["aim.com"]		= {name="aol.lua"}

-- netscape
freepops.MODULES_MAP["netscape.net"]    = {name="netscape.lua"}

-- squirrelmail
freepops.MODULES_MAP["mydom.com"]	= {name="squirrelmail.lua"}

-- tre.it
freepops.MODULES_MAP["tre.it"]		= {name="tre.lua"}

-- supereva.it
freepops.MODULES_MAP["supereva.it"]	= {name="supereva.lua"}
freepops.MODULES_MAP["supereva.com"]	= {name="supereva.lua"}
freepops.MODULES_MAP["freemail.it"]	= {name="supereva.lua"}
freepops.MODULES_MAP["freeweb.org"]	= {name="supereva.lua"}
freepops.MODULES_MAP["mybox.it"]	= {name="supereva.lua"}
freepops.MODULES_MAP["superdada.com"]	= {name="supereva.lua"}
freepops.MODULES_MAP["cicciociccio.com"]= {name="supereva.lua"}
freepops.MODULES_MAP["mp4.it"]		= {name="supereva.lua"}
freepops.MODULES_MAP["dadacasa.com"]	= {name="supereva.lua"}
freepops.MODULES_MAP["clarence.com"]	= {name="supereva.lua"}
freepops.MODULES_MAP["concento.it"]	= {name="supereva.lua"}

-- mail.com
freepops.MODULES_MAP["mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["email.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["iname.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["cheerful.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["consultant.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["europe.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["mindless.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["earthling.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["myself.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["post.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["techie.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["usa.com"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["writeme.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["2die4.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["artlover.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["bikerider.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["catlover.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["cliffhanger.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["cutey.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["doglover.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["gardener.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["hot-shot.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["inorbit.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["loveable.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["mad.scientist.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["playful.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["poetic.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["popstar.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["saintly.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["seductive.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["soon.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["whoever.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["winning.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["witty.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["yours.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["africamail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["arcticmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["asia.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["australiamail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["japan.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["samerica.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["usa.com"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["berlin.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["dublin.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["london.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["madrid.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["moscowmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["munich.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["nycmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["paris.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["rome.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["sanfranmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["singapore.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["tokyo.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["accountant.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["adexec.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["allergist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["alumnidirector.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["archaeologist.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["chemist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["clerk.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["columnist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["comic.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["consultant.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["counsellor.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["deliveryman.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["diplomats.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["doctor.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["dr.com"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["engineer.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["execs.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["financier.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["geologist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["graphic-designer.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["hairdresser.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["insurer.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["journalist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["lawyer.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["legislator.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["lobbyist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["minister.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["musician.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["optician.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["pediatrician.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["presidency.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["priest.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["programmer.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["publicist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["realtyagent.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["registerednurses.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["repairman.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["representative.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["rescueteam.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["scientist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["sociologist.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["teacher.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["techie.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["technologist.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["umpire.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["02.to"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["111.ac"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["123post.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["168city.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["2friend.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["65.to"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["852.to"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["86.to"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["886.to"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["aaronkwok.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["acmilan-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["allstarstats.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["amrer.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["amuro.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["amuromail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["anfieldroad-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["arigatoo.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["arsenal-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["barca-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["baseball-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["basketball-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["bayern-munchen.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["birmingham-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["blackburn-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["bsdmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["bsdmail.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["c-palace.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["celtic-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["charlton-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["chelsea-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["china139.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["chinabyte.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["chinahot.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["chinarichholdings.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["coolmail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["coventry-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["cseek.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["cutemail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["daydiary.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["dbzmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["derby-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["dhsmail.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["dokodemo.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["doomo.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["doramail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["e-office.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["e-yubin.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["eracle.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["eu-mail.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["everton-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["eyah.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["ezagenda.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["fastermail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["femail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["fiorentina-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["football-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["forest-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["freeid.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["fulham-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["gaywiredmail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["genkimail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["gigileung.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["glay.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["globalcom.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["golf-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["graffiti.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["gravity.com.au"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["hackermail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["highbury-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["hitechweekly.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["hkis.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["hkmag.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["hkomail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["hockey-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["hollywood-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["ii-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["iname.ru"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["inboexes.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["inboxes.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["inboxes.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["inboxes.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["insingapore.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["intermilan-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["ipswich-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["isleuthmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["jane.com.tw"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["japan1.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["japanet.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["japanmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["jayde.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["jcom.ac"]			= {name="mailcom.lua"}
freepops.MODULES_MAP["jedimail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["joinme.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["joyo.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["jpn1.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["jpol.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["jpopmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["juve-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["juventus-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["juventusmail.net"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["kakkoii.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["kawaiimail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["kellychen.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["keromail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["kichimail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["kitty.cc"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["kittymail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["kittymail.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["lazio-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["lazypig.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["leeds-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["leicester-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["leonlai.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["linuxmail.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["liverpool-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["luvplanet.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["mailasia.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["mailjp.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["mailpanda.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["mailunion.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["man-city.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["manu-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["marchmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["markguide.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["maxplanet.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["megacity.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["middlesbrough-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["miriamyeung.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["miriamyeung.com.hk"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["myoffice.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["nctta.org"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["netmarketingcentral.com"] = {name="mailcom.lua"}
freepops.MODULES_MAP["nettalk.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["newcastle-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["nihonjin1.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["nihonmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["norikomail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["norwich-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["old-trafford.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["operamail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["otakumail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["outblaze.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["outgun.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["pakistans.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["pokefan.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["portugalnet.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["powerasia.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["qpr-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["rangers-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["realmadrid-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["regards.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["ronin1.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["rotoworld.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["samilan.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["searcheuropemail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["sexymail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["sheff-wednesday.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["slonline.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["smapxsmap.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["southampton-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["speedmail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["sports-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["starmate.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["sunderland-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["sunmail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["supermail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["supermail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["surfmail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["surfy.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["taiwan.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["talknet.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["teddy.cc"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["tennis-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["tottenham-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["utsukushii.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["uymail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["villa-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["webcity.ca"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["webmail.lu"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["welcomm.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["wenxuecity.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["westham-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["wimbledon-mail.com"]	= {name="mailcom.lua"}
freepops.MODULES_MAP["windrivers.net"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["wolves-mail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["wongfaye.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["worldmail.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["worldweb.ac"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["isleuthmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["x-lab.cc"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["xy.com.tw"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["yankeeman.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["yyhmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["verizonmail.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["lycos.com" ]		= {name="mailcom.lua"}
freepops.MODULES_MAP["unforgettable.com" ]	= {name="mailcom.lua"}
freepops.MODULES_MAP["mail.org" ]		= {name="mailcom.lua"}
freepops.MODULES_MAP["italymail.com" ]		= {name="mailcom.lua"}
freepops.MODULES_MAP["computer4u.com"]		= {name="mailcom.lua"}
freepops.MODULES_MAP["mexico.com"]		= {name="mailcom.lua"}

-- mail2world
freepops.MODULES_MAP["mail2.*%.com" ]		= {name="mail2world.lua", 
						   regex=true}

-- juno plugin
freepops.MODULES_MAP["netzero.net"]	= {name="juno.lua"}	
freepops.MODULES_MAP["netzero.com"]	= {name="juno.lua"}	
freepops.MODULES_MAP["juno.com"]   	= {name="juno.lua"}     

-- fastmail
freepops.MODULES_MAP["123mail.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["150mail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["150ml.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["16mail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["2-mail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["4email.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["50mail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["airpost.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["allmail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["bestmail.us"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["cluemail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["elitemail.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["emailgroups.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["emailplus.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["emailuser.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["eml.cc"]		= {name="fastmail.lua"}
freepops.MODULES_MAP["fastem.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fast-email.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastemail.us"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastemailer.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastest.cc"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastimap.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastmail.cn"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastmail.com.au"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastmail.fm"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastmail.us"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastmail.co.uk"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastmail.to"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fmail.co.uk"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fast-mail.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastmailbox.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fastmessaging.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fea.st"]		= {name="fastmail.lua"}
freepops.MODULES_MAP["f-m.fm"]		= {name="fastmail.lua"}
freepops.MODULES_MAP["fmailbox.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fmgirl.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["fmguy.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["ftml.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["hailmail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["imap.cc"]		= {name="fastmail.lua"}
freepops.MODULES_MAP["imap-mail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["imapmail.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["internet-e-mail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["internetemails.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["internet-mail.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["internetmailing.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["jetemail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["justemail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["letterboxes.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailandftp.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailas.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailbolt.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailc.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailcan.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mail-central.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailforce.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailftp.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailhaven.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailingaddress.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailite.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailmight.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailnew.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mail-page.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailsent.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailservice.ms"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailup.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mailworks.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["ml1.net"]		= {name="fastmail.lua"}
freepops.MODULES_MAP["mm.st"]		= {name="fastmail.lua"}
freepops.MODULES_MAP["myfastmail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["mymacmail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["nospammail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["ownmail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["petml.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["postinbox.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["postpro.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["proinbox.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["promessage.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["realemail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["reallyfast.biz"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["reallyfast.info"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["rushpost.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["sent.as"]		= {name="fastmail.lua"}
freepops.MODULES_MAP["sent.at"]		= {name="fastmail.lua"}
freepops.MODULES_MAP["sent.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["speedpost.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["speedymail.org"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["ssl-mail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["swift-mail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["the-fastest.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["theinternetemail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["the-quickest.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["veryfast.biz"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["veryspeedy.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["warpmail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["xsmail.com"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["yepmail.net"]	= {name="fastmail.lua"}
freepops.MODULES_MAP["your-mail.com"]	= {name="fastmail.lua"}

-- criticalpath
freepops.MODULES_MAP["canada.com"] = {name="criticalpath.lua"}

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
	args={host="http://www.freepops.org/it"}
}

freepops.MODULES_MAP["freepops.en"] 	= {
	name="flatnuke.lua",
	args={host="http://www.freepops.org/en"}
}

-- rss backended news plugin
freepops.MODULES_MAP["aggregator"] 		= {
	name="aggregator.lua"
}

-- rss binded domains
freepops.MODULES_MAP["freepops.rss.en"] 	= {
	name="aggregator.lua",
	args={host="http://www.freepops.org/en/rss.php"}
}

freepops.MODULES_MAP["freepops.rss.it"] 	= {
	name="aggregator.lua",
	args={host="http://www.freepops.org/it/rss.php"}
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
-- remember that multiple rules are supported, but must be comma-separated. 
-- for example
--  { ".*@foo.xx" , ".*@example.org", "root@here.xx" }
-- is a valid LUA syntax, while
--  { ".*@foo.xx" ".*@example.org" "root@here.xx" }
-- or 
--  {
--    ".*@foo.xx" 
--    ".*@example.org" 
--    "root@here.xx"
--  }
-- are wrong.

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
	os.getenv("FREEPOPSLUA_PATH_UPDATES") or "./",
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
