#!/bin/sh

PREFIX=/Users/gares/freepops/
set -e
#set -x

rm -rf expat-1.95.8
tar -xvzf expat-1.95.8.tar.gz
cd expat-1.95.8
CFLAGS="-arch ppc -arch i386 -arch x86_64 -arch ppc64 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
./configure --prefix=$PREFIX --disable-shared && \
make && sudo make install
file .libs/libexpat.a
