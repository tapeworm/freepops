#!/bin/sh

set -e
set -x

rm -rf fltk-1.1.7
tar -xvzf fltk-1.1.7-source.tar.gz
cd fltk-1.1.7
CFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3" \
CXXFLAGS="-arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.3.9.sdk/" \
./configure --prefix=/Users/enricotassi/freepops/lib --disable-gl --disable-threads 
make
for X in lib/*.a; do mv $X $X.10.3; done
mv fluid/fluid fluid/fluid.10.3
make clean
CFLAGS="-arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
CXXFLAGS="-arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
./configure --prefix=/Users/enricotassi/freepops/lib --disable-gl --disable-threads
make
for X in lib/*.a; do mv $X $X.10.4; done
mv fluid/fluid fluid/fluid.10.4
lipo -create -output lib/libfltk.a lib/libfltk.a.10.3 lib/libfltk.a.10.4
lipo -create -output lib/libfltk_forms.a lib/libfltk_forms.a.10.3 lib/libfltk_forms.a.10.4
lipo -create -output lib/libfltk_images.a lib/libfltk_images.a.10.3 lib/libfltk_images.a.10.4
lipo -create -output lib/libfltk_jpeg.a lib/libfltk_jpeg.a.10.3 lib/libfltk_jpeg.a.10.4
lipo -create -output lib/libfltk_png.a lib/libfltk_png.a.10.3 lib/libfltk_png.a.10.4
lipo -create -output fluid/fluid fluid/fluid.10.3 fluid/fluid.10.4
file lib/libfltk.a
sudo make install
