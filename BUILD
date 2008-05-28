Compile on osx with Xcode 2.4.1
===============================

Build a custom expat for Xcode 2.4.1 sdks with the script: 
 
 scripts/compile-expat-universal.sh

Then ./configure.sh osx-ARCH. If you like to build a universal binary
use make -C buildfactory osx

Cross compile for win32 
=======================

  cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops/ co mingw32_freepops
  cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops/ co packages
  cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops/ co freepops
  apt-get install mingw32 mingw32-runtime mingw32-binutils 
  apt-get install xpm2wico sysutils nsis bison flex automake-1.7 autoconf
  cd packages
  make win

  The compilation needs a line like this one in your /etc/sudoers:
  
   user ALL = NOPASSWD: /usr/bin/dpkg -i mingw32-*, /usr/bin/dpkg -r mingw32-*
  
  Where user is your username. But be careful, this is not a really good
  practice for non-home pc since running dpkg -i is enough to run arbitrary
  code as root.

