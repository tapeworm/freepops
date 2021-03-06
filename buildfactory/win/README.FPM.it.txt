FreePOPs & Mail Script FAQ (versione FAQ 1.7)

Autore: Pegasus (p3g4sus(chiocciola)users.sourceforge.net)


Che cos'�?
-----------

Si tratta di uno script scritto in VBS (Visual Basic Scripting) il cui scopo
principale � di automatizzare l'avvio, insieme con FreePOPs, di un client email 
selezionato dall'utente (SMC) e la successiva chiusura di FreePOPs alla chiusura di SMC.

Quali sono i requisiti software per poterlo usare?
--------------------------------------------------

Se il sistema operativo � Microsoft Windows ME o 2000 o XP o 2003 basta aver installato FreePOPs.
Se il sistema operativo � Microsoft Windows 95 o 98 o NT 4.0 oltre ad avere installato FreePOPs, si deve aver 
installati il WMI (Windows Management Instrumentation) e il WSH (Windows Scripting Host).
Link (gratuiti) per il download:
- WMI per Windows 95 o 98: 
  http://download.microsoft.com/download/platformsdk/wmi9x/1.5/W9X/EN-US/wmi9x.exe
- WMI per Windows NT 4.0:
  http://download.microsoft.com/download/platformsdk/wmint4/1.5/NT4/EN-US/wmint4.EXE
- WSH: usare il motore di ricerca che trovate su http://www.microsoft.com/downloads cercando "WSH".
Vi consiglio comunque di provare prima ad eseguire lo script SENZA aver installato i suddetti aggiornamenti. 
Se riscontrate l'errore di runtime con codice 800A01B0, allora vi serve il WMI. Se invece Windows non 
sa con che programma aprire il file .vbs allora avete bisogno del WSH.


Cosa fa esattamente?
---------------------

- Se SMC � gi� aperto, NIENTE.
- Se � gi� aperto FreePOPs ma non il SMC, apre il SMC. All'uscita dal SMC
  FreePOPs viene lasciato aperto.
- Se FreePOPs e il SMC sono chiusi, apre Freepops e dopo 10 ms il SMC.
  All'uscita da quest'ultimo, chiude FreePOPs.


Come scelgo il mail client che lo script fa partire?
----------------------------------------------------

Questo script legge i dati sul client email da far partire in un file di configurazione ("fpm.ini").
Qualora questo file non esista, lo script legge dal registro di windows le informazioni sul mail client di
default e crea il file di configurazione inserendovi i dati su tale mail client. Se dunque volete far partire
FreePOPs col mail client di default, non dovreste aver bisogno di nessuna configurazione. Viceversa, se volete far
partire FreePOPs insieme a un client email diverso da quello di default dovete andare a modidicare (utilizzando
ad esempio il Blocco Note di Windows) il file di configurazione il quale ha la seguente struttura:
Prima riga -> Numero di millisecondi che si devono attendere tra l'avvio di FreePOPs e l'avvio di SMC.
Seconda riga -> Percorso completo (comprensivo di nome del file) del file di avvio del SMC.
Terza riga -> Nome del file di avvio del SMC.
Quarta riga (opzionale) -> Argomenti da linea di comando con cui va avviato SMC.

Esempio di file di configurazione:

10
%ProgramFiles%\Outlook Express\msimn.exe
msimn.exe


Come si installa?
------------------

Non c'� bisogno di nessuna installazione. Per eseguire lo script, basta fare doppio click su "freepopsd.vbs". 
Per facilitarne l'utilizzo consiglio di aggiornare i collegamenti con cui avviate SMC e farli puntare al file
"freepopsd.vbs".


Come faccio se devo avviare FreePOPs con degli argomenti da linea di comando?
------------------------------------------------------------------------------

Niente di pi� semplice: gli argomenti da linea di comando che dovete passare a FreePOPs passateli allo script.


Come imposto il mail client di default?
----------------------------------------

1- Eseguite Internet Explorer.
2- Dal menu "Strumenti", selezionate "Opzioni Internet".
3- Dalla linguetta "Programmi" impostate il client email di default desiderato alla voce "E-Mail".


Come mai il mio antivirus mi sconsiglia di eseguire lo script?
--------------------------------------------------------------

Ci sono molti virus che sfruttano la potenza del VBS per fare seri danni al PC.
Ovviamente non � il caso di questo script. State tranquilli e fate star
tranquillo, se possibile, anche il vostro antivirus. 

Quando eseguo lo script ottengo l'errore di runtime con codice 800A01B0. Come mai?
----------------------------------------------------------------------------------

Probabilmente stai usando Windows 95 o 98 o NT 4.0 e non hai il WMI installato. Leggi la sezione requisiti per 
maggiori informazioni.


Come faccio per segnalare un bug?
----------------------------------

Vi prego di aprire lo script col blocco note di Windows e di sostituire

'wScript.echo "MailClientPath = " & Sh.RegRead (key)

con

wScript.echo "MailClientPath = " & Sh.RegRead (key)

Salvate il vbs e eseguitelo ancora appuntando tutto l'output.
Mandate una email a p3g4sus@users.sourceforge.net con una descrizione dell'errore e
dell'output. Grazie mille delle segnalazioni. Provveder� alle correzioni il
prima possibile.


Storia delle versioni
---------------------

v. 1.4 Corretti bug minori.

v. 1.3 Ora lo script non legge pi� ogni volta il percorso del mail client da avviare dal
       registro di Windows. Legge il registro (e crea il file di configurazione) solo quando 
       non esiste il file "fpm.ini". Quando questo esiste, il mail client da avviare viene
       letto al suo interno. 
       Questo permette di personalizzare il mail client da avviare.

v. 1.2 Corretto un bug che non faceva funzionare lo script quando il client di default 
       era indicato nel registro di windows senza le virgolette (").

v. 1.0 Prima versione.