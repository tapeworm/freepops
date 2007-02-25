#!/bin/sh

set -e
set -x

rm -rf openssl-0.9.7l/
tar -xvzf  openssl-0.9.7l.tar.gz
cd openssl-0.9.7l/

./Configure --prefix=/Users/enricotassi/freepops/lib 'darwin/gcc:gcc -O3 -fomit-frame-pointer -DB_ENDIAN -arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3 -D_REENTRANT'
make || true
mv libssl.a SAVE.libssl.a.10.3.ppc
mv libcrypto.a SAVE.libcrypto.a.10.3.ppc

make clean

./Configure --prefix=/Users/enricotassi/freepops/lib 'darwin/gcc:gcc -O3 -fomit-frame-pointer -fno-common -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4 -D_REENTRANT'
make || true
mv libssl.a SAVE.libssl.a.10.4.i386
mv libcrypto.a SAVE.libcrypto.a.10.4.i386

lipo -create -output libssl.a SAVE.libssl.a.10.3.ppc SAVE.libssl.a.10.4.i386
lipo -create -output libcrypto.a SAVE.libcrypto.a.10.3.ppc SAVE.libcrypto.a.10.4.i386
file libssl.a
file libcrypto.a

sudo make install

#eof
