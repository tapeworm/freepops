FreePOPs 0.0.4 Readme file


Questo pacchetto contiene la distribuzione pre-compilata di FreePOPs per sistemi Mac OS X. Per usarla, lanciate un Terminale, spostatevi nella directory dove è installato FreePOPs e lanciate ./freepopsd, con i parametri preferiti. Vedi freepopsd -h o i manuali inclusi nella directory doc/ per una lista completa di opzioni a riga di comando.
In caso di problemi nell'aggiornamento da versioni precedenti consigliamo di cancellare a mano la directory con la versione precedente e anche il file /Library/Receipts/FreePOPs-x.y.z.pkg (x.y.z e' la versione precedente di FreePOPs installata).

Gli utenti di LiberoPOPs troveranno utile l'howto per la migrazione da LP a FP allegato.

Per favore ricordatevi di generare un log verboso con le opzioni '-w -l log.txt' se avete bisogno di chiedere aiuto agli sviluppatori o di segnalare un bug.
Per chiedere assistenza, DOPO aver letto la documentazione inclusa, potete guardare:

- Sito ufficiale su http://freepops.sourceforge.net
- Un tutorial per principianti su http://freepops.sourceforge.net/it/tutorial/index.shtml
- Forum degli utenti su http://liberopops.diludovico.it/


ChangeLog:

07/06/2004 0.0.4 fix/source-reorganization release
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