#!/bin/sh

set -e
set -x

rm -rf zlib-1.2.3
tar -xvzf zlib-1.2.3.tar.gz
cd zlib-1.2.3
CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.3.9.sdk/" \
./configure --prefix=/Users/enricotassi/freepops/lib 
CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.3.9.sdk/" \
make
mv libz.a SAVE.libz.a.10.3
make clean
CFLAGS="-arch i386 -arch x86_64 -arch ppc64 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
./configure --prefix=/Users/enricotassi/freepops/lib 
CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
make
mv libz.a libz.a.10.4
lipo -create -output libz.a SAVE.libz.a.10.3 libz.a.10.4
sudo make install
file libz.a
