FreePOPs & Mail Script FAQ

Autore: Pegasus (holdencaufield@wooow.it)



Che cos'è?
-----------

Si tratta di uno script scritto in VBS (Visual Basic Scripting) il cui scopo
principale è di automatizzare l'avvio, insieme con FreePOPs, del client email
di default (DMC) e la successiva chiusura di FreePOPs alla chiusura del DMC.



Cosa fa esattamente?
---------------------

- Se il DMC è già aperto, NIENTE.
- Se è già aperto FreePOPs ma non il DMC, apre il DMC. All'uscita dal DMC
  FreePOPs viene lasciato aperto.
- Se FreePOPs e il DMC sono chiusi, apre Freepops e dopo 10 ms il DMC.
  All'uscita da quest'ultimo, chiude FreePOPs.



Come si installa?
------------------

Non c'è bisogno di nessuna installazione. Basta che il file .vbs sia nella
stessa cartella di freepopsd.exe. Per facilitarne l'utilizzo consiglio di
aggiornare i collegamenti con cui avviate DMC e farli puntare al file .vbs
dello script.



Come faccio se devo avviare FreePOPs con degli argomenti da linea di comando?
------------------------------------------------------------------------------

Niente di più semplice: gli argomenti da linea di comando che dovete passare a FreePOPs passateli allo script.



Come mai il mio antivirus mi sconsiglia di eseguire lo script?
--------------------------------------------------------------

Ci sono molti virus che sfruttano la potenza del VBS per fare seri danni al PC.
Ovviamente non è il caso di questo script. State tranquilli e fate star
tranquillo, se possibile, anche il vostro antivirus. 




Come faccio per segnalare un bug?
----------------------------------

Vi prego di aprire lo script col blocco note di Windows e di sostituire

'wScript.echo MailClientPath = Sh.RegRead (key)

con

wScript.echo MailClientPath = Sh.RegRead (key)

Salvate il vbs e eseguitelo ancora appuntando tutto l'output.
Mandate una email a holdencaufield@wooow.it con una descrizione dell'errore e
dell'output. Grazie mille delle segnalazioni. Provvederò alle correzioni il
prima possibile.


