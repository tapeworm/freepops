File ReadMe di FreePOPs

Questo pacchetto contiene la distribuzione pre-compilata di FreePOPs per sistemi Mac OS X. Per usarla, dovrebbe bastare installarla; verranno copiati due file in /Library/StartupItems/FreePOPs (o uno in /Library/LaunchDaemons se usate Mac OS X Tiger) che faranno partire automaticamente FreePOPs ad ogni avvio del sistema.

Se cio' non dovesse accadere potete copiare manualmente i file contenuti nella directory "script" (presente dove avete installato FreePOPs) nel percorso detto sopra; se usate Mac OS X Tiger dovrete copiare il file freepopsd.plist, altrimenti gli altri due. In freepopsd.plist dovrete cambiare ogni occorrenza di /Applications/FreePOPs con il percorso reale in cui avete installato FreePOPs; se usate Mac OS X Panther o Jaguar dovrete cambiare nel file chiamato FreePOPs la riga che dice "DIR=" aggiungendo dopo il segno di uguaglianza la directory dove FreePOPs e' installato (ad es. /Applications/FreePOPs).

Se desiderate far partire FreePOPs solo manualmente dovrete eliminare i file nella directory /Library/StartupItems/FreePOPs (o solo freepopsd.plist in /Library/LaunchDaemons su Mac OS Tiger - non cancellate gli altri file eventualmente presenti nella directory); aprite un Terminale, spostatevi nella directory dove avete installato FreePOPs e lanciate il comando ./freepopsd, con le opzioni che preferite.

In caso di problemi nell'aggiornamento da versioni precedenti consigliamo di cancellare a mano la directory con la versione precedente e anche il file /Library/Receipts/FreePOPs-x.y.z.pkg (x.y.z e' la versione precedente di FreePOPs installata).

Gli utenti di LiberoPOPs troveranno utile l'howto per la migrazione da LP a FP allegato.

Per favore ricordatevi di generare un log verboso con le opzioni '-w -l log.txt' se avete bisogno di chiedere aiuto agli sviluppatori o di segnalare un bug.
Per chiedere assistenza, DOPO aver letto la documentazione inclusa, potete guardare:

- Sito ufficiale su http://www.freepops.org
- Un tutorial per principianti su http://www.freepops.org/it/tutorial/index.shtml
- Forum degli utenti su http://freepops.diludovico.it/
- Manuali completi su:
  http://www.freepops.org/it/files/manual-it.pdf (IT version)
  http://www.freepops.org/it/files/manual.pdf    (EN version)


ChangeLog:

