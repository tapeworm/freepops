FreePOPs 0.0.4 Readme file


This package contains the pre-compiled distribution of FreePOPs for Mac OS X systems. In order to use it, run <path>/freepopsd from a Terminal, with your favorite command line options, where <path> is the path you've installed FreePOPs into. See freepopsd -h or the manuals included in the doc/ directory for a complete list of command line options.
In case you have problems updating from an older version, delete manually the directory you've installed FreePOPs into as well as the /Library/Receipts/FreePOPs-x.y.z.pkg file (x.y.z is the version of FreePOPs currently installed).

LiberoPOPs users might find the included LP-to-FP migration howto useful.

Please remember to generate a verbose log with the '-w -l log.txt' options if you need to ask the developers for help or report a bug.
To ask for help, AFTER you've read the included documentation, you may look at:

- Official website at http://freepops.sourceforge.net
- A tutorial for dummies at http://freepops.sourceforge.net/en/tutorial/index.shtml
- Users forum at http://liberopops.diludovico.it/


ChangeLog:

04/06/2004 0.0.4 fix/source-reorganization release
- added pkg file for Mac OS X
- documentation for new modules
- badguy feature added to tin.lua
- added luabind module (factorization of useful functions in bindings)
- completely removed tolua++
- bindings for getdate made by hand
- bindings for popserver made bt hand
- fixed curl_lua for truncating a connection in the callback
- session_lua now are made by hand, no more tolua++
- log_lua now are made by hand, no more tolua++
- all webmail now share the same get_name and get_domain functions
- fixed stupid fetchmail top bug
- log used to write liberopopsd :)
- fixed "-" in the username
- proxy AUTH issue workaround (not able to make CURLAUTH_ANY work)
28/05/2004 0.0.3 bomb! feature release
- updated the doc
- fixed libero webmail to new mlex and new libero webmail (nobody
noticed it has changed so much? probably because the old mlex continued
to work properly, but it was a lucky case!)
- added tin webmail
- improved mlex.c with <script> correct handling
- fixed http redirection 
- fixed browser cookie generation
19/05/2004 0.0.2 feature release [never released]
- added browser:get_head(url,extraheader) method
- fixed Makefile verbosity
- fixed chroot jail for curl
- fixed aggregator.lua (thanks to bimbosuper)
- added games.gamespot.com and news.gamespot.com aggregator domains
- updated the website with FAQ section
- documentation for curl_lua and psock
- moved popforward from luasocket to psock (poor but works)
- added portablesocket_lua module
- updated libero.lua to new browser.lua
- updated serialize.lua to support "self serializing" objects
- updates support.lua to support new browser.lua
- updated browser.lua do cURL
- moved to cURL
- added curl_lua module
01/05/2004 0.0.1 first public release