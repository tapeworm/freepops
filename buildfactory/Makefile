include $(CONFIG)

VERSION=$(shell grep "\#define VERSION" ../config.h | cut -d \" -f 2)

H=@

help:
	$(H)echo
	$(H)echo "here we build all the distributed packages"
	$(H)echo
	$(H)echo "Targets are: all dist-{osx,win,deb,rpm,gen,tgz,obsd}"
	$(H)echo

all: dist-deb dist-rpm dist-win dist-gen 

clean:
	$(H)rm -rf _*_ freepops-[0-9\.]*.tar.gz
	$(H)cd osx;rm -rf FreePOPs.app

dist-win: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _win_/freepops
	$(H)[ -d _win_/freepops-$(VERSION) ] || \
		tar -xzf freepops-$(VERSION).tar.gz -C _win_
	$(H)cd _win_/freepops-$(VERSION);\
		./configure.sh win;\
		$(MAKE) all; \
		#$(MAKE) manual;
	$(H)cp _win_/freepops-$(VERSION)/src/freepopsd.exe _win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/modules/lib/libpthread.dll \
		_win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/src/lua/*.lua _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/modules/include/*.lua _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/config.lua _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/buildfactory/freepopsd.vbs \
		_win_/freepops/
	$(H)#cp _win_/freepops-$(VERSION)/doc/manual.pdf _win_/freepops/
	$(H)#cp _win_/freepops-$(VERSION)/doc/manual-it.pdf _win_/freepops/

	$(H)cp _win_/freepops-$(VERSION)/COPYING _win_/freepops/COPYING.txt
	$(H)cp _win_/freepops-$(VERSION)/ChangeLog _win_/freepops/ChangeLog.txt

	$(H)unix2dos _win_/freepops/COPYING.txt
	$(H)unix2dos _win_/freepops/ChangeLog.txt

	$(H)sed 's/\%FREEPOPSVERSION/$(VERSION)/' freepops.nsi.in > \
		_win_/freepops/freepops.nsi

	$(H)xpm2wico -f freepops-setup.xpm _win_/freepops/freepops-setup.ico
	$(H)xpm2wico -f freepops-remove.xpm _win_/freepops/freepops-remove.ico
	
	$(H)cp /usr/local/cross-tools/i386-mingw32msvc/bin/libcurl-3.dll \
		_win_/freepops/libcurl-3.dll
	$(H)cp /usr/local/cross-tools/i386-mingw32msvc/bin/expat.dll \
		_win_/freepops/expat.dll
	$(H)/usr/local/cross-tools/i386-mingw32msvc/bin/strip \
		_win_/freepops/*.exe _win_/freepops/*.dll
	$(H)cd _win_/freepops/;\
		wine /usr/local/NSIS/makensis.exe freepops.nsi

	$(H)mkdir ../dist-win || true
	$(H)cp _win_/freepops/FreePOPs-$(VERSION).exe ../dist-win
	
	$(H)rm -r _win_

dist-rpm: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _rpm_/build
	$(H)mkdir -p _rpm_/tmp
	$(H)sed 's/\%FREEPOPSVERSION/$(VERSION)/' freepops.spec.in > \
		_rpm_/freepops.spec
	$(H)cp freepops-$(VERSION).tar.gz _rpm_
	$(H)rpm --rcfile rpmrc -ba _rpm_/freepops.spec
	$(H)mkdir ../dist-rpm || true
	$(H)cp _rpm_/*.rpm ../dist-rpm
	$(H)rm -rf _rpm_
	
dist-gen:
	mkdir -p ../dist-gen || true
	@cp freepops.ebuild.gz \
		../dist-gen/freepops-$(VERSION).ebuild.gz

dist-deb: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _deb_
	$(H)[ -d _deb_/freepops-$(VERSION) ] || \
		tar -xzf freepops-$(VERSION).tar.gz -C _deb_
	$(H)cd _deb_/freepops-$(VERSION);\
		./configure.sh linux;\
		dpkg-buildpackage -rfakeroot -us -uc
	$(H)mkdir -p ../dist-deb/freepops || true
	$(H)cp _deb_/*.tar.gz _deb_/*.deb _deb_/*.dsc _deb_/*.changes \
		../dist-deb/freepops
	$(H)lintian -i ../dist-deb/freepops/*.deb \
		../dist-deb/freepops/*.dsc ||true
	$(H)cd ../dist-deb/freepops/;echo "freepops optional mail" \
		> overridefile
	$(H)cd ../dist-deb/freepops/;dpkg-scanpackages . overridefile > Packages
	$(H)cd ../dist-deb/freepops/;dpkg-scansources . overridefile > Sources
	$(H)cd ../dist-deb/freepops/;gzip -f Packages Sources

	$(H)rm -rf _deb_

dist-osx: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _osx_
	$(H)[ -d _osx_/freepops-$(VERSION) ] || \
		tar -xzf freepops-$(VERSION).tar.gz -C _osx_
	$(H)cd _osx_/freepops-$(VERSION); ./configure.sh osx; $(MAKE) all
	$(H)mkdir -p ../dist-osx/FreePOPs/doc
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include
	$(H)cp osx/README-osx.txt ../dist-osx/FreePOPs/
	$(H)cd _osx_/freepops-$(VERSION);\
		cp COPYING AUTHORS ChangeLog config.lua ../../../dist-osx/FreePOPs/
	$(H)cd _osx_/freepops-$(VERSION)/doc;\
		cp LP-FP-HOWTO.txt MANUAL.txt ../../../../dist-osx/FreePOPs/doc/
	$(H)cd _osx_/freepops-$(VERSION)/src;strip freepopsd;\
		cp freepopsd ../../../../dist-osx/FreePOPs/src/
	$(H)cd ../dist-osx/FreePOPs/;ln -s src/freepopsd freepopsd
	$(H)cd _osx_/freepops-$(VERSION)/src/lua;\
		cp *.lua ../../../../../dist-osx/FreePOPs/src/lua
	$(H)cd _osx_/freepops-$(VERSION)/modules/include;\
		cp *.lua ../../../../../dist-osx/FreePOPs/modules/include
	$(H)cat osx/ReadMe.en.txt > osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog >> osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat osx/ReadMe.it.txt > osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog >> osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)rm -rf _osx_

dist-osx-static: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _osx_
	$(H)[ -d _osx_/freepops-$(VERSION) ] || \
		tar -xzf freepops-$(VERSION).tar.gz -C _osx_
	$(H)cd _osx_/freepops-$(VERSION); ./configure.sh osx-static; $(MAKE) all
	$(H)mkdir -p ../dist-osx/FreePOPs/doc
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include
	$(H)cp osx/README-osx.txt ../dist-osx/FreePOPs/
	$(H)cd _osx_/freepops-$(VERSION);\
		cp COPYING AUTHORS ChangeLog config.lua ../../../dist-osx/FreePOPs/
	$(H)cd _osx_/freepops-$(VERSION)/doc;\
		cp LP-FP-HOWTO.txt MANUAL.txt ../../../../dist-osx/FreePOPs/doc/
	$(H)cd _osx_/freepops-$(VERSION)/src;strip freepopsd;\
		cp freepopsd ../../../../dist-osx/FreePOPs/src/
	$(H)cd ../dist-osx/FreePOPs/;ln -s src/freepopsd freepopsd
	$(H)cd _osx_/freepops-$(VERSION)/src/lua;\
		cp *.lua ../../../../../dist-osx/FreePOPs/src/lua
	$(H)cd _osx_/freepops-$(VERSION)/modules/include;\
		cp *.lua ../../../../../dist-osx/FreePOPs/modules/include
	$(H)cat osx/ReadMe.en.txt > osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog >> osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat osx/ReadMe.it.txt > osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog >> osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)rm -rf _osx_

osx-app: freepops-$(VERSION).tar.gz Info.plist
	$(H)mkdir -p _osx_
	$(H)[ -d _osx_/freepops-$(VERSION) ] || \
		tar -xzf freepops-$(VERSION).tar.gz -C _osx_
	$(H)cd _osx_/freepops-$(VERSION);\
		./configure.sh osx;\
	$(H)cd _osx_;$(MAKE) all
	$(H)mkdir -p osx/FreePOPs.app/Contents/MacOS
	$(H)mkdir -p osx/FreePOPs.app/Contents/Resources/Italian.lproj
	$(H)mkdir -p osx/FreePOPs.app/Contents/Resources/English.lproj
	$(H)mkdir -p osx/FreePOPs.app/Contents/Resources/SharedSupport
	$(H)cp osx/Info.plist osx/FreePOPs.app/Contents/
	$(H)cd _osx_/freepops-$(VERSION)/src;strip freepopsd;\
		cp freepopsd ../../../osx/FreePOPs.app/Contents/MacOS/
	$(H)cp _osx_/freepops-$(VERSION)/src/lua/*.lua osx/FreePOPs.app/Contents/Resources/
	$(H)cp _osx_/freepops-$(VERSION)/modules/include/*.lua osx/FreePOPs.app/Contents/Resources/
	$(H)cp _osx_/freepops-$(VERSION)/*.lua osx/FreePOPs.app/Contents/Resources/
	$(H)echo "APPL????" > osx/FreePOPs.app/Contents/PkgInfo
	$(H)cp osx/freepops.icns osx/FreePOPs.app/Contents/Resources
	$(H)rm -f osx/Info.plist
	$(H)rm -rf _osx_

Info.plist:
	$(H)echo "<?xml version="1.0" encoding="UTF-8"?>" > osx/Info.plist
	$(H)echo "<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">" >> osx/Info.plist
	$(H)echo "<plist version="1.0">" >> osx/Info.plist
	$(H)echo "<dict>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleDevelopmentRegion</key>" >> osx/Info.plist
	$(H)echo "	<string>English</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleDisplayName</key>" >> osx/Info.plist
	$(H)echo "	<string>FreePOPs</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleExecutable</key>" >> osx/Info.plist
	$(H)echo "	<string>freepopsd</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleGetInfoString</key>" >> osx/Info.plist
	$(H)echo "	<string>$(VERSION), Copyright 2004 Alessio Caprari, Nicola Cocchiaro, Enrico Tassi, Simone Vellei</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleIconFile</key>" >> osx/Info.plist
	$(H)echo "	<string>freepops.icns</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleIdentifier</key>" >> osx/Info.plist
	$(H)echo "	<string>net.sf.freepops</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleInfoDictionaryVersion</key>" >> osx/Info.plist
	$(H)echo "	<string>6.0</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleName</key>" >> osx/Info.plist
	$(H)echo "	<string>FreePOPs</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundlePackageType</key>" >> osx/Info.plist
	$(H)echo "	<string>APPL</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleSignature</key>" >> osx/Info.plist
	$(H)echo "	<string>????</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleShortVersionString</key>" >> osx/Info.plist
	$(H)echo "	<string>$(VERSION)</string>" >> osx/Info.plist
	$(H)echo "	<key>CFBundleVersion</key>" >> osx/Info.plist
	$(H)echo "	<string>$(VERSION)</string>" >> osx/Info.plist
	$(H)echo "	<key>NSPrincipalClass</key>" >> osx/Info.plist
	$(H)echo "	<string>NSApplication</string>" >> osx/Info.plist
	$(H)echo "	<key>NSHumanReadableCopyright</key>" >> osx/Info.plist
	$(H)echo "	<string>Copyright 2004 Alessio Caprari, Nicola Cocchiaro, Enrico Tassi, Simone Vellei</string>" >> osx/Info.plist
	$(H)echo "</dict>" >> osx/Info.plist
	$(H)echo "</plist>" >> osx/Info.plist

dist-obsd:
	$(H)cd ..;./configure.sh obsd || true
	$(H)cd ..;$(MAKE) install
	$(H)cd openbsd;pkg_create -f CONTENTS -c COMMENT -d DESC \
	-D DISPLAY freepops-$(VERSION)
	$(H)gzip openbsd/freepops-$(VERSION)
	$(H)mv openbsd/freepops-$(VERSION).gz freepops-$(VERSION).tgz
	
freepops-$(VERSION).tar.gz: 
	$(H)cd ..;./configure.sh linux || true
	$(H)$(MAKE) -C .. tgz-dist
	$(H)cp ../dist-tgz/freepops-$(VERSION).tar.gz .
	
	
