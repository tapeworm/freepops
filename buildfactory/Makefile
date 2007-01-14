ifeq ($(CONFIG),)
 include ../config
else
 include $(CONFIG)
endif

VERSION=$(shell grep "\#define VERSION" ../config.h | cut -d \" -f 2)

H=@

help:
	$(H)echo
	$(H)echo "here we build all the distributed packages"
	$(H)echo
	$(H)echo "Targets are: all dist-{osx,osx-static,win,deb,rpm,gen,tgz,obsd,zip}"
	$(H)echo

all: dist-deb dist-rpm dist-win-e-zip #dist-gen dist-slack

clean:
	$(H)rm -rf _*_ freepops-[0-9\.]*.tar.gz
	$(H)cd osx;rm -rf FreePOPs.app
	$(H)cd win;rm -rf *.exe

dist-win: dist-win-e-zip-openssl
dist-zip: dist-win-e-zip-openssl
dist-win-gnutls: dist-win-e-zip-gnutls
dist-zip-gnutls: dist-win-e-zip-gnutls

dist-win-e-zip-step1:
	$(H)mkdir -p _win_/freepops/LUA/
	$(H)mkdir -p _win_/freepops/C/
	$(H)[ -d _win_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _win_

dist-win-e-zip-step2-openssl:
	$(H)cd _win_/freepops-$(VERSION);\
		./configure.sh win -fltk-ui;\
		$(MAKE) all; \
		#$(MAKE) manual
		
dist-win-e-zip-step2-gnutls:
	$(H)cd _win_/freepops-$(VERSION);\
		./configure.sh win-gnutls -fltk-ui;\
		$(MAKE) all; \
		#$(MAKE) manual

dist-win-e-zip-step3:
	$(H)$(MAKE) -C win CONFIG=../_win_/freepops-$(VERSION)/config
	$(H)cp _win_/freepops-$(VERSION)/src/freepopsd.exe _win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/src/libfp.dll  _win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/updater-ui/fltk/updater_fltk.dll \
		_win_/freepops/C
	$(H)cp _win_/freepops-$(VERSION)/modules/lib/libpthread.dll \
		_win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/src/lua/*.lua _win_/freepops/LUA/
	$(H)cp _win_/freepops-$(VERSION)/modules/include/*.lua \
		_win_/freepops/LUA/
	$(H)for D in _win_/freepops-$(VERSION)/modules/include/*/; do\
		N=`ls $$D/*.lua $$D/*/*.lua $$D/*/*/*.lua 2>/dev/null | wc -l`;\
		if [ $$N -gt 0 ]; then \
			cp -r $$D _win_/freepops/LUA/;\
		fi;\
	done
	$(H)cp _win_/freepops-$(VERSION)/config.lua _win_/freepops/LUA/
	$(H)cp _win_/freepops-$(VERSION)/buildfactory/freepopsd.vbs \
		_win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/buildfactory/README.FPM.*.txt \
		_win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/buildfactory/SERVICE.*.txt \
		_win_/freepops/	
	$(H)cp win/*.exe _win_/freepops/

	$(H)cp _win_/freepops-$(VERSION)/COPYING _win_/freepops/COPYING.txt
	$(H)cp _win_/freepops-$(VERSION)/ChangeLog _win_/freepops/ChangeLog.txt

	$(H)unix2dos _win_/freepops/COPYING.txt
	$(H)unix2dos _win_/freepops/ChangeLog.txt
	$(H)unix2dos _win_/freepops/README.FPM.*.txt
	$(H)unix2dos _win_/freepops/SERVICE.*.txt

dist-win-e-zip-step4-openssl:
	$(H)\
	  DLLPATH=`grep DLLPATH _win_/freepops-$(VERSION)/config|cut -d= -f2`;\
		cp $$DLLPATH/libcurl.dll _win_/freepops/libcurl.dll;\
		cp $$DLLPATH/libexpat.dll _win_/freepops/libexpat.dll;\
		cp $$DLLPATH/libintl-8.dll _win_/freepops/;\
		cp $$DLLPATH/libz.dll _win_/freepops/libz.dll
dist-win-e-zip-step4-gnutls:
	$(H)\
	  DLLPATH=`grep DLLPATH _win_/freepops-$(VERSION)/config|cut -d= -f2`;\
		cp $$DLLPATH/libcurl.dll _win_/freepops/libcurl.dll;\
		cp $$DLLPATH/libexpat.dll _win_/freepops/libexpat.dll;\
		cp $$DLLPATH/libintl-8.dll _win_/freepops/;\
		cp $$DLLPATH/libz.dll _win_/freepops/libz.dll; \
		cp $$DLLPATH/libgnutls.dll _win_/freepops/libgnutls.dll;\
		cp $$DLLPATH/libgcrypt.dll _win_/freepops/libgcrypt.dll;\
		cp $$DLLPATH/libgpg-error.dll _win_/freepops/libgpg-error.dll

dist-win-e-zip-step5:
	$(H)STRIP=`grep ^STRIP _win_/freepops-$(VERSION)/config|cut -d = -f 2`;\
		$$STRIP _win_/freepops/*.exe \
			_win_/freepops/*.dll \
			_win_/freepops/C/*.dll

	$(H)sed 's/\%FREEPOPSVERSION/$(VERSION)/' freepops.nsi.in > \
		_win_/freepops/freepops.nsi

	$(H)xpm2wico -f freepops-setup.xpm _win_/freepops/freepops-setup.ico
	$(H)xpm2wico -f freepops-remove.xpm _win_/freepops/freepops-remove.ico
	$(H)xpm2wico -f ../updater-ui/fltk/freepops-updater-fltk-32.xpm \
		_win_/freepops/freepops-updater.ico

	# NSIS is now a debian package :)
	#
	#$(H)cd _win_/freepops/;\
	#	wine /usr/local/NSIS/makensis.exe freepops.nsi
	#
	$(H)cd _win_/freepops/; makensis freepops.nsi
	
	$(H)mkdir ../dist-win || true
	$(H)mv _win_/freepops/FreePOPs-$(VERSION).exe ../dist-win
	
	# end of installer 

	$(H)cd _win_/freepops/; cp LUA/config.lua .
	#$(H)cp _win_/freepops-$(VERSION)/doc/manual.pdf _win_/freepops/
	#$(H)cp _win_/freepops-$(VERSION)/doc/manual-it.pdf _win_/freepops/
	
	$(H)cd _win_/freepops/; rm freepops-setup.ico
	$(H)cd _win_/freepops/; rm freepops-remove.ico
	
	$(H)cd _win_/;zip -r -9 FreePOPs-$(VERSION).zip freepops
	$(H)mv _win_/FreePOPs-$(VERSION).zip ../dist-win
	
	$(H)rm -r _win_

dist-win-e-zip-step6-openssl:
	$(H)mv ../dist-win/FreePOPs-$(VERSION).exe \
		../dist-win/FreePOPs-$(VERSION)-openssl.exe
	$(H)mv ../dist-win/FreePOPs-$(VERSION).zip \
		../dist-win/FreePOPs-$(VERSION)-openssl.zip
	
dist-win-e-zip-step6-gnutls:
	$(H)mv ../dist-win/FreePOPs-$(VERSION).exe \
		../dist-win/FreePOPs-$(VERSION)-gnutls.exe
	$(H)mv ../dist-win/FreePOPs-$(VERSION).zip \
		../dist-win/FreePOPs-$(VERSION)-gnutls.zip

dist-win-e-zip-openssl: freepops-$(VERSION).tar.gz \
	dist-win-e-zip-step1 \
	dist-win-e-zip-step2-openssl \
	dist-win-e-zip-step3 \
	dist-win-e-zip-step4-openssl \
	dist-win-e-zip-step5 \
	dist-win-e-zip-step6-openssl 

dist-win-e-zip-gnutls: freepops-$(VERSION).tar.gz \
	dist-win-e-zip-step1 \
	dist-win-e-zip-step2-gnutls \
	dist-win-e-zip-step3 \
	dist-win-e-zip-step4-gnutls \
	dist-win-e-zip-step5 \
	dist-win-e-zip-step6-gnutls 

dist-rpm: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _rpm_/build
	$(H)mkdir -p _rpm_/tmp
	$(H)sed 's/\%FREEPOPSVERSION/$(VERSION)/' freepops.spec.in > \
		_rpm_/freepops.spec
	$(H)cp freepops-$(VERSION).tar.gz _rpm_
	$(H)rpmbuild --rcfile rpmrc -ba _rpm_/freepops.spec
	$(H)mkdir ../dist-rpm || true
	$(H)cp _rpm_/*.rpm ../dist-rpm
	$(H)rm -rf _rpm_
	
dist-gen:
	mkdir -p ../dist-gen || true
	@cp freepops.ebuild.gz \
		../dist-gen/freepops-$(VERSION).ebuild.gz
	
dist-deb-hackwoody:
	$(H)cd _deb_/freepops-$(VERSION);\
		cp buildfactory/debian-woody/* debian/
dist-deb-hacksarge:
	$(H)cd _deb_/freepops-$(VERSION);\
		cp buildfactory/debian-sarge/* debian/
		
dist-deb-hackbpo:
	$(H)cd _deb_/freepops-$(VERSION);\
		V=`head -n 1 debian/changelog | sed "s/.*(\([^)]*\)).*/\1/"`;\
		DR=`echo $$V | cut -d - -f 2`;\
		UV=`echo $$V | cut -d - -f 1`;\
		BPOR=`expr $$DR - 1`bpo$$DR;\
		dch -D sarge-backports -b -v $$UV-$$BPOR backports.org release

dist-deb-woody: deb-preamble dist-deb-hackwoody dist-deb-real
dist-deb-sarge: deb-preamble dist-deb-hacksarge dist-deb-real
dist-deb-sid: dist-deb
dist-deb-etch: dist-deb
	
dist-deb: deb-preamble dist-deb-real

deb-preamble: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _deb_
	$(H)[ -d _deb_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _deb_
	$(H)cp freepops-$(VERSION).tar.gz \
		_deb_/freepops_$(VERSION).orig.tar.gz
	$(H)cd _deb_/freepops-$(VERSION);\
		cp -fr buildfactory/debian .

dist-deb-real: 
	$(H)cd _deb_/freepops-$(VERSION);\
		./configure.sh linux;\
		dpkg-buildpackage -rfakeroot -us -uc
	$(H)mkdir -p ../dist-deb/freepops || true
	$(H)cp _deb_/*.tar.gz _deb_/*.deb _deb_/*.dsc _deb_/*.changes \
		_deb_/*.diff.gz ../dist-deb/freepops
	$(H)lintian -vi ../dist-deb/freepops/*.changes ||true
	$(H)cd ../dist-deb/freepops/; \
		echo -e "freepops optional mail\nfreepops-doc optional mail" \
			> overridefile
	$(H)cd ../dist-deb/freepops/;\
		dpkg-scanpackages . overridefile > Packages
	$(H)cd ../dist-deb/freepops/;\
		dpkg-scansources . overridefile > Sources
	$(H)cd ../dist-deb/freepops/;gzip -f Packages Sources

	$(H)rm -rf _deb_

debian-dsc-woody: deb-preamble dist-deb-hackwoody debian-dsc-real
debian-dsc-sarge: deb-preamble dist-deb-hacksarge debian-dsc-real
debian-dsc-bpo: deb-preamble dist-deb-hacksarge dist-deb-hackbpo debian-dsc-real
debian-dsc-etch: debian-dsc
debian-dsc-sid: debian-dsc

debian-dsc: deb-preamble debian-dsc-real

debian-dsc-real:
	$(H)mkdir -p ../dist-deb/freepops || true
	$(H)cd _deb_/;\
		dpkg-source -b freepops-$(VERSION)
	$(H)cp _deb_/*.tar.gz _deb_/*.dsc \
		_deb_/*.diff.gz ../dist-deb/freepops
	$(H)# to avoid problems with umask and pbuilder
	$(H)chmod a+r ../dist-deb/freepops/* 
	$(H)rm -rf _deb_

dist-slack: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _slack_
	$(H)mkdir -p dist-slack
	$(H)[ -d _slack_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _slack_
	$(H)cd _slack_/freepops-$(VERSION); \
		./configure.sh linux-slack; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR="../../dist-slack/"
	$(H)cd dist-slack; \
		strip usr/bin/freepopsd; \
		mkdir -p install; \
		cp ../slackware/slack-desc install; \
		cp ../slackware/slack-required install; \
		mkdir -p etc/rc.d; \
		cp ../slackware/freepops.conf etc/freepops; \
		cp ../slackware/rc.freepops etc/rc.d; \
		mv usr/share/man usr/man; \
		mv usr/share/doc usr/doc; \
		gzip usr/man/man1/freepopsd.1; \
		rm usr/doc/freepops/MANUAL.txt; \
		mv usr/doc/freepops usr/doc/freepops-$(VERSION); \
		cp ../_slack_/freepops-$(VERSION)/AUTHORS usr/doc/freepops-$(VERSION); \
		cp ../_slack_/freepops-$(VERSION)/COPYING usr/doc/freepops-$(VERSION); \
		cp ../_slack_/freepops-$(VERSION)/ChangeLog usr/doc/freepops-$(VERSION); \
		cp ../_slack_/freepops-$(VERSION)/README usr/doc/freepops-$(VERSION); \
		chown -R root.root .; \
		chmod 755 .; \
		chown root.bin usr/bin ; \
		chmod 755 etc/rc.d/rc.freepops; \
		chmod 644 usr/share/freepops/lua/*; \
		rm -rf usr/share/freepops/lua_unofficial; \
		makepkg --chown n freepops-$(VERSION)-i386-1.tgz; \
		rm -rf etc; \
		rm -rf install; \
		rm -rf usr
	$(H)rm -rf _slack_
	
dist-osx: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _osx_
	$(H)[ -d _osx_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _osx_
	$(H)cd _osx_/freepops-$(VERSION); ./configure.sh osx; $(MAKE) all
	$(H)mkdir -p ../dist-osx/FreePOPs/doc
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua_unofficial
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/browser
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/lxp
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/soap
	$(H)mkdir -p ../dist-osx/FreePOPs/script
	$(H)cp osx/README-osx.txt ../dist-osx/FreePOPs/
	$(H)cp osx/Install_resources/FreePOPs osx/Install_resources/StartupParameters.plist osx/Install_resources/freepopsd.plist ../dist-osx/FreePOPs/script
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
	$(H)cd _osx_/freepops-$(VERSION)/modules/include/browser;\
		cp *.lua ../../../../../../dist-osx/FreePOPs/modules/include/browser
	$(H)cd _osx_/freepops-$(VERSION)/modules/include/lxp;\
		cp *.lua ../../../../../../dist-osx/FreePOPs/modules/include/lxp
	$(H)cd _osx_/freepops-$(VERSION)/modules/src/luasoap;\
		cp *.lua ../../../../../../dist-osx/FreePOPs/modules/include/soap
	$(H)mv ../dist-osx/FreePOPs/modules/include/soap.lua ../dist-osx/FreePOPs/modules/include/soap/
	$(H)cat osx/ReadMe.en.txt > osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog >> osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat osx/ReadMe.it.txt > osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog >> osx/Install_resources/Italian.lproj/ReadMe.txt
#	$(H)rm -rf _osx_

dist-osx-static: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _osx_
	$(H)[ -d _osx_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _osx_
	$(H)cd _osx_/freepops-$(VERSION); ./configure.sh osx-static; $(MAKE) all
	$(H)mkdir -p ../dist-osx/FreePOPs/doc
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua_unofficial
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/browser
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/lxp
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/soap
	$(H)mkdir -p ../dist-osx/FreePOPs/script
	$(H)cp osx/README-osx.txt ../dist-osx/FreePOPs/
	$(H)cp osx/Install_resources/FreePOPs osx/Install_resources/StartupParameters.plist osx/Install_resources/freepopsd.plist ../dist-osx/FreePOPs/script
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
	$(H)cd _osx_/freepops-$(VERSION)/modules/include/browser;\
		cp *.lua ../../../../../../dist-osx/FreePOPs/modules/include/browser
	$(H)cd _osx_/freepops-$(VERSION)/modules/include/lxp;\
		cp *.lua ../../../../../../dist-osx/FreePOPs/modules/include/lxp
	$(H)cd _osx_/freepops-$(VERSION)/modules/src/luasoap;\
		cp *.lua ../../../../../../dist-osx/FreePOPs/modules/include/soap
	$(H)mv ../dist-osx/FreePOPs/modules/include/soap.lua ../dist-osx/FreePOPs/modules/include/soap/
	$(H)cat osx/ReadMe.en.txt > osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog >> osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat osx/ReadMe.it.txt > osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog >> osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)rm -rf _osx_

# osx-app
# This is currently broken, DO NOT USE
# 
# 
osx-app: freepops-$(VERSION).tar.gz Info.plist
	$(H)mkdir -p _osx_
	$(H)[ -d _osx_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _osx_
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

dist-tgz: freepops-$(VERSION).tar.gz
	$(H)mkdir -p dist-tgz
	$(H)mv freepops-$(VERSION).tar.gz dist-tgz

freepops-$(VERSION).tar.gz: 
	$(H)cd ..;./configure.sh linux || true
	$(H)$(MAKE) -C .. tgz-dist
	$(H)mv ../dist-tgz/freepops-$(VERSION).tar.gz .
	$(H)rm -rf ../dist-tgz
