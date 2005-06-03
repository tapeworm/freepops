Contenuto di questo file:

- File Readme di FreePOPs (Italiano)
  1. Esecuzione di FreePOPs
  2. Maggiori informazioni
- FreePOPs Readme file (English)
  1. Running FreePOPs
  2. Additional info

--------------------------------------------------------------------------------

File Readme di FreePOPs (Italiano)

1. Esecuzione di FreePOPs

Questo pacchetto contiene la distribuzione pre-compilata di FreePOPs per 
sistemi Mac OS X. Per usarla, dovrebbe bastare installarla; verranno copiati 
due file in /Library/StartupItems/FreePOPs/ (oppure un file freepopsd.plist in 
/System/Library/LaunchDaemons se usate Mac OS X Tiger) che faranno partire 
automaticamente FreePOPs ad ogni avvio del sistema.

Se cio' non dovesse accadere potete copiare manualmente i file contenuti nella 
directory "script" (presente dove avete installato FreePOPs) nel percorso detto 
sopra; se usate Mac OS X Tiger dovrete copiare il file freepopsd.plist, 
altrimenti gli altri due. In freepopsd.plist dovrete sostituire ogni occorrenza 
di /Applications/FreePOPs/ con il percorso reale dove avete installato FreePOPs;
se usate Mac OS X Panther o Jaguar e' necessario cambiare nel file FreePOPs la 
riga che dice "DIR=" aggiungendo dopo il segno di uguaglianza la directory dove 
FreePOPs e' installato (ad es. /Applications/FreePOPs).

Se desiderate far partire FreePOPs solo manualmente dovrete eliminare i file 
nella directory /Library/StartupItems/FreePOPs (o cancellare 
/System/Library/LaunchDaemons/freepopsd.plist su Mac OS X Tiger - non gli altri 
eventualmente presenti nella directory); aprite un Terminale, spostatevi 
nella directory dove avete installato FreePOPs e lanciate il comando 
./freepopsd, con le opzioni che preferite.

2. Maggiori informazioni

Lanciate freepopsd -h da Terminale o leggete i manuali che trovate su:
http://www.freepops.org/it/files/manual-it.pdf (IT version)
http://www.freepops.org/it/files/manual.pdf    (EN version)
per una completa lista delle opzioni.

Potete chiedere aiuto scrivendo sul forum presso http://freepops.diludovico.it.
Per favore ricordate di generare un log verboso con le opzioni '-w -l 
log.txt' se volete chiedere aiuto agli sviluppatori o segnalare un bug.

Guardate http://www.freepops.org per ulteriori informazioni.

--------------------------------------------------------------------------------

FreePOPs Readme file (English)

1. Running FreePOPs

This package contains the pre-compiled distribution of FreePOPs for Mac OS X 
systems. To use it you should just have to install it; two files will be copied 
in /Library/StartupItems/FreePOPs (or one file in /System/Library/LaunchDaemons 
if you use Mac OS X Tiger) that will run FreePOPs automatically at every 
system boot.

If that doesn't happen you may manually copy the files contained in the 
"script" directory (which is where you've installed FreePOPs) in the 
aforementioned path; if you use Mac OS X Tiger you will have to copy the 
freepopsd.plist file, otherwise you'll copy the other two. In freepopsd.plist 
you will have to change every occurrence of /Applications/FreePOPs with the 
real path where you've installed FreePOPs; if you use Mac OS X Panther or 
Jaguar you will have to change the line that says "DIR=" (in the file named 
FreePOPs) by adding the path FreePOPs is installed into after the equals sign 
(for example /Applications/FreePOPs).

If you want to run FreePOPs only manually you will have to delete the files in 
the /Library/StartupItems directory (or freepopsd.plist in 
/System/Library/LaunchDaemons/ under Mac OS X Tiger - don't delete the other 
files in that directory if there are any); run a Terminal, move to the 
directory you've installed FreePOPs into then run ./freepopsd, with your 
favorite command line options.

2. Additional info

See freepopsd -h or the manuals you find at:
http://www.freepops.org/it/files/manual-it.pdf (IT version)
http://www.freepops.org/it/files/manual.pdf    (EN version)
for a complete list of command line options.

You may ask for help posting on the forum at http://freepops.diludovico.it.
Please remember to generate a verbose log with the '-w -l log.txt' options 
if you need to ask the developers for help or report a bug.

See http://www.freepops.org if you need extra information.
