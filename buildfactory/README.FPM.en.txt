FreePOPs & Mail Script FAQ (FAQ version 1.4)

Author: Pegasus (p3g4sus@users.sourceforge.net)


What is it?
-----------

It is a VBS Script. Its aim is to automatically start, togheter with FreePOPs,
an email client selected by the user (SMC) and to close FreePOPs when you close the SMC.


What does it exactly do?
------------------------

- If your SMC is already open, NOTHING.
- If FreePOPs is already open but your SMC is closed, it starts your SMC. When
  you quit from you SMC, FreePOPs is left open.
_ If FreePOPs and your SMC are both closed, it starts FreePOPs and, after 10
  ms, the SMC. When you quit from your SMC, the script closes FreePOPs too.


How do I select the mail client that the script hs to start?
------------------------------------------------------------

This script reads the informations about the mail client to start in a configuration file ("fpm.ini").
If this file does not exist, the script reads from Windows registry the informations about the default
mail client and creates a configuration file with the informations about this mail client. So if you
want to start FreePOPs with your default mail client, you should have no need to configure anything.
But if you want to start FreePOPs with a mail client different from the default one, you have to modify
(using, e.g., Windows Notepad) the configuration file that is structured as follows:
First Line -> Number of milliseconds to wait between the start of FreePOPs and the start of SMC.
Second Line -> Complete path (with file name) of the SMC executable file.
Thrid Line -> Name of the executable file of the SMC.
Fourth Line (optional) -> Command line arguments to pass to the SMC.

Example of configuration file:

10
%ProgramFiles%\Outlook Express\msimn.exe
msimn.exe


How do I install it?
--------------------

There is no need of any setup. To execute the script, simply double-click the file "freepopsd.vbs". 
My advice is to update your links to your SMC in a way that, when you click on them, 
you start this .vbs script.


How can I use the script if I want to start FreePOPs with command line arguments?
----------------------------------------------------------------------------------

It's very simple. Simply start this script with the command line arguments that
you want to pass to FreePOPs.


How do I set my SMC?
--------------------

1- Start Internet Explorer.
2- From the "Tools" menu, select "Internet Options".
3- Click the "Programs" tab, set the desired default mail client from the "E-mail" drop-down list.


Why does my antivirus system warn me before executing the script?
-----------------------------------------------------------------

This is because the power of VBS language has several times been used for
malicious proposes. Obviously this script is not a virus. Don't worry and, if
possible, tell your antivirus not to warn you again for this file.



What can I do if I find a bug?
-----------------------------

Please open the script with windows notepad and replace this line

'wScript.echo "MailClientPath = " & Sh.RegRead (key)

with

wScript.echo "MailClientPath = " & Sh.RegRead (key)

Save the modified vbs and start it. Take note of output and errors. Please send
to p3g4sus@users.sourceforge.net output and errors togheter with a short description
of the problem. Thanks for reporting bugs. I'll fix them as soon as possible.


Changelog
----------

v. 1.4 Some minor bugs corrected.

v. 1.3 Now the script does not read the path of mail client to start from windows registry. 
       It reads the windows registry (and creates the configuration file) only when "fpm.ini"
       does not exist. When this file exists, the path of the mail client to start is read on it.
       This allows the user to select a mail client to start different from the default one.

v. 1.2 Corrected a bug that prevented the script to work when the SMC path was not written in the 
       windows registry between quotation marks (").

v. 1.0 First release.

