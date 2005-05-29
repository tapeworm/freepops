FreePOPs Readme file

This package contains the pre-compiled distribution of FreePOPs for Mac OS X systems. To use it you should just have to install it; two files will be copied in /Library/StartupItems/FreePOPs (or one to /System/Library/LaunchDaemons if you use Mac OS X Tiger) that will run FreePOPs automatically at every system boot.

If that doesn't happen you may manually copy the files contained in the "script" directory (which is where you've installed FreePOPs) in the aforementioned path; if you use Mac OS X Tiger you'll have to copy freepopsd.plist, otherwise you'll copy the other two. In freepopsd.plist you'll have to change every occurrence of /Applications/FreePOPs to the real path where you've installed FreePOps; if you use Mac OS X Panther or Jaguar you will have to change the line that says "DIR=" (in the file named FreePOPs) by adding the path FreePOPs is installed into after the equals sign (for example /Applications/FreePOPs).

If you want to run FreePOPs only manually you will have to delete the files in the /Library/StartupItems directory (or freepopsd.plist in /System/Library/LaunchDaemons under Mac OS X Tiger - don't delete the other files in the directory, if any); run a Terminal, move to the directory you've installed FreePOPs into then run ./freepopsd, with your favorite command line options.

In case you have problems updating from an older version, delete manually the directory you've installed FreePOPs into as well as the /Library/Receipts/FreePOPs-x.y.z.pkg file (x.y.z is the version of FreePOPs currently installed).

LiberoPOPs users might find the included LP-to-FP migration howto useful.

Please remember to generate a verbose log with the '-w -l log.txt' options if you need to ask the developers for help or report a bug.
To ask for help, AFTER you've read the documentation, you may look at:

- Official website at http://www.freepops.org
- A tutorial for dummies at http://freepops.sourceforge.net/en/tutorial/index.shtml
- Users forum at http://freepops.diludovico.it/
- Complete manuals at:
  http://freepops.sourceforge.net/it/files/manual-it.pdf (IT version)
  http://freepops.sourceforge.net/it/files/manual.pdf    (EN version)


ChangeLog:

