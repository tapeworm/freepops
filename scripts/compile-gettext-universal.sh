#!/bin/sh

PREFIX=/Users/gares/freepops/
set -e
#set -x

rm -rf gettext-0.17/
tar -xvzf gettext-0.17.tar.gz
cd gettext-0.17/
CFLAGS="-arch ppc -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
./configure --prefix=$PREFIX --disable-shared && \
make && sudo make install
file .libs/libgettext.a
