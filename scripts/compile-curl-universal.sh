#!/bin/sh

PREFIX=/Users/gares/freepops/
set -e
#set -x

rm -rf curl-7.18.1
tar -xvzf curl-7.18.1.tar.gz
cd curl-7.18.1
CFLAGS="-arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
./configure --prefix=$PREFIX --disable-shared --with-ssl=/Developer/SDKs/MacOSX10.4u.sdk/usr/include/openssl/ && \
make && sudo make install && make distclean
CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
./configure --prefix=$PREFIX --disable-shared --with-ssl=/Developer/SDKs/MacOSX10.4u.sdk/usr/include/openssl/ && \
make
lipo -create -output ../libcurl.a lib/.libs/libcurl.a $PREFIX/lib/libcurl.a
sudo mv ../libcurl.a $PREFIX/lib/
file $PREFIX/lib/libcurl.a

# && sudo make install
