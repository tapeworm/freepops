FreePOPs & Mail Script FAQ

Author: Pegasus (holdencaufield@wooow.it)



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
  ms, the

DMC. When you quit from your DMC, the script closes FreePOPs too.



How do I install it?
--------------------

There is no need of any setup. It's important that you execute the script from
the folder where the file freepopsd.exe is. My advice is to update your links
to your DMC in a way that, when you click on them, you start this .vbs script.



How can I use the script if I want to start FreePOPs with command line
arguments?
----------------------------------------------------------------------

It's very simple. Simply start this script with the command line arguments that
you want to pass to FreePOPs.



Why does my antivirus system warn me before executing the script?
-----------------------------------------------------------------

This is because the power of VBS language has several times been used for
malicious proposes. Obviously this script is not a virus. Don't worry and, if
possible, tell your antivirus not to warn you again for this file.



What can I do if I find a bug?
-----------------------------

Please open the script with windows notepad and replace this line

'wScript.echo MailClientPath = Sh.RegRead (key)

with

wScript.echo MailClientPath = Sh.RegRead (key)

Save the modified vbs and start it. Take note of output and errors. Please send
to holdencaufield@wooow.it output and errors togheter with a short description
of the problem. Thanks for reporting bugs. I'll fix them as soon as possible.


