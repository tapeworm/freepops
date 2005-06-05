
Cross compile for win32 
=======================

  cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops/ co zlib_deb
  cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops/ co expat_deb
  cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops/ co openssl_deb
  cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops/ co curl_deb
  cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops/ co mingw32_freepops
  apt-get install mingw32 mingw32-runtime mingw32-binutils 
  apt-get install xpm2wico sysutils nsis bison flex 
  cd mingw32_freepops
  make 

  [ outdated, but kept in case of fallback ]

  The cross compiler can be found http://libsdl.org/extras/win32/cross/ ,
  you should install it to /usr/local/cross-tools/
  
  Then checkout curl and expat modules from CVS, they contain an 
  already build binary you should untar to / (and will put someting 
  inside the cross compiler path) (cvs is cvs.sf.net:/cvsroot/freepops/)

  Download NSIS (currently windows only) and with wine install it to
  /usr/local/NSIS (http://nsis.sf.net)

  You need unix2dos (debian sysutils), xpm2wico (debian xpm2wico),
  flex, bison.


Distro-cross Debian build
=========================

  Istall pbuilder, checkout (cvs is cvs.sf.net:/cvsroot/freepops/) the 
  packages module and do a meke debian (it expects that freepops and 
  packages are brother directories.

