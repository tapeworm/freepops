FreePOPs & Mail Script FAQ

Author: Pegasus (p3g4sus@users.sourceforge.net)


What is it?
-----------

It is a VBS Script. Its aim is to automatically start, togheter with FreePOPs,
your default mail client (DMC) and to close FreePOPs when you close your DMC.


What does it exactly do?
------------------------

- If your DMC is already open, NOTHING.
- If FreePOPs is already open but your DMC is closed, it starts your DMC. When
  you quit from you DMC, FreePOPs is left open.
_ If FreePOPs and your DMC are both closed, it starts FreePOPs and, after 10
  ms, the DMC. When you quit from your DMC, the script closes FreePOPs too.


How do I install it?
--------------------

There is no need of any setup. To execute the script, simply double-click the file "freepopsd.vbs". 
My advice is to update your links to your DMC in a way that, when you click on them, 
you start this .vbs script.


How can I use the script if I want to start FreePOPs with command line arguments?
----------------------------------------------------------------------------------

It's very simple. Simply start this script with the command line arguments that
you want to pass to FreePOPs.


How do I set my DMC?
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

v. 1.1 Corrected a bug that prevented the script to work when the DMC path was not written in the 
       windows registry between quotation marks (").

v. 1.0 First release.

