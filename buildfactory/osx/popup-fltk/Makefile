all: fmessage

fmessage: fmessage.10.3.ppc fmessage.10.4.i386
	lipo -create -output $@ $^
	/Users/enricotassi/freepops/lib/bin/fltk-config --post $@ 
	file $@


fmessage.10.3.ppc: fmessage.cpp
	g++ -arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ \
		-mmacosx-version-min=10.3 \
		-Wl,-syslibroot,/Developer/SDKs/MacOSX10.3.9.sdk/ \
		-I/Users/enricotassi/freepops/lib/include \
		-L/Users/enricotassi/freepops/lib/lib \
		-o $@ $< \
		-lfltk -framework Carbon -framework ApplicationServices

fmessage.10.4.i386: fmessage.cpp
	g++ -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ \
		-mmacosx-version-min=10.4 \
		-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/ \
		-I/Users/enricotassi/freepops/lib/include \
		-L/Users/enricotassi/freepops/lib/lib \
		-o $@ $< \
		-lfltk -framework Carbon -framework ApplicationServices 

clean:
	rm -f fmessage fmessage.10.3.ppc fmessage.10.4.i386
