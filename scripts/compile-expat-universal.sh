#!/bin/sh

set -e
#set -x

rm -rf expat-1.95.8
tar -xvzf expat-1.95.8.tar.gz
cd expat-1.95.8
CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.3.9.sdk/" \
./configure --prefix=/Users/enricotassi/freepops/lib --disable-shared
CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.3.9.sdk/" \
make || (/bin/sh ./libtool --silent --mode=link gcc -Wl,-arch,ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3 -Wall -Wmissing-prototypes -Wstrict-prototypes -fexceptions -DHAVE_EXPAT_CONFIG_H   -I./lib -I. -no-undefined -version-info 6:0:5 -rpath /Users/enricotassi/freepops/lib-ppc-10.3/lib -Wl:-Wl,-syslibroot,/Developer/SDKs/MacOSX10.3.9.sdk/ -o libexpat.la lib/xmlparse.lo lib/xmltok.lo lib/xmlrole.lo && make) 
mv .libs .libs.10.3
make clean
CFLAGS="-arch i386 -arch x86_64 -arch ppc64 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
./configure --prefix=/Users/enricotassi/freepops/lib --disable-shared
CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
make || (/bin/sh ./libtool --silent --mode=link gcc -Wl,-arch,i386 -Wl,-arch,x86_64 -Wl,-arch,ppc64 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4 -Wall -Wmissing-prototypes -Wstrict-prototypes -fexceptions -DHAVE_EXPAT_CONFIG_H   -I./lib -I. -no-undefined -version-info 5:0:5 -rpath /Users/enricotassi/freepops/lib/lib -Wl,-Wl:-syslibroot:/Developer/SDKs/MacOSX10.4u.sdk/ -o libexpat.la lib/xmlparse.lo lib/xmltok.lo lib/xmlrole.lo && make)
mv .libs .libs.10.4
mkdir .libs/
lipo -create -output .libs/libexpat.a .libs.10.3/libexpat.a .libs.10.4/libexpat.a
cp -RP .libs.10.3/*la .libs.10.3/*lai .libs
sudo make install
file .libs/libexpat.a
