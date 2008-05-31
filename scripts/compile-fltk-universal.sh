#!/bin/sh

set -e
set -x

PREFIX=/Users/gares/freepops/

rm -rf fltk-1.1.7
tar -xvzf fltk-1.1.7-source.tar.gz
cd fltk-1.1.7
mkdir private
for ARCH in ppc i386; do
	make clean
	CFLAGS="-arch $ARCH -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
	CXXFLAGS="-arch $ARCH -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4" \
	LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/" \
	./configure --prefix=$PREFIX --disable-gl --disable-threads && make
	for X in lib/*.a; do mv $X private/`basename $X`.$ARCH; done
	mv fluid/fluid private/fluid.$ARCH
done

for X in lib/libfltk.a lib/libfltk_forms.a lib/libfltk_images.a lib/libfltk_jpeg.a lib/libfltk_png.a fluid/fluid; do
	lipo -create -output $X private/`basename $X`.ppc private/`basename $X`.i386
done
file lib/libfltk.a
sudo make install
