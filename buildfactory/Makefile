# This file contains only scripts to build packages supported by the 
# upstream authors that are: win, osx, debian, tar.gz
# other scripts are included at the end, but are not supported by the 
# upstream authors

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
	$(H)echo "Targets are: all dist-{osx,win,deb,rpm,gen,tgz,obsd,zip}"
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
dist-win-openssl: dist-win-e-zip-openssl
dist-zip-openssl: dist-win-e-zip-openssl

dist-win-e-zip-step1:
	$(H)mkdir -p _win_/freepops/LUA/
	$(H)mkdir -p _win_/freepops/C/
	$(H)[ -d _win_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _win_

dist-win-e-zip-step2-openssl:
	$(H)cd _win_/freepops-$(VERSION);\
		./configure.sh win -fltk-ui;\
		$(MAKE) all
		
dist-win-e-zip-step2-gnutls:
	$(H)cd _win_/freepops-$(VERSION);\
		./configure.sh win-gnutls -fltk-ui;\
		$(MAKE) all

dist-win-e-zip-step3:
	$(H)$(MAKE) -C win CONFIG=../_win_/freepops-$(VERSION)/config
	$(H)cp _win_/freepops-$(VERSION)/src/freepopsd.exe _win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/src/libfp.dll  _win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/updater-ui/fltk/updater_fltk.dll \
		_win_/freepops/C/
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
	$(H)cp _win_/freepops-$(VERSION)/buildfactory/win/freepopsd.vbs \
		_win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/buildfactory/win/README.FPM.*.txt \
		_win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/buildfactory/win/SERVICE.*.txt \
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
		cp $$DLLPATH/cryptoeay32.dll _win_/freepops/cryptoeay32.dll;\
		cp $$DLLPATH/ssleay32.dll _win_/freepops/ssleay32.dll;\
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
		cp $$DLLPATH/libgnutls-13.dll _win_/freepops/libgnutls-13.dll;\
		cp $$DLLPATH/libgcrypt.dll _win_/freepops/libgcrypt.dll;\
		cp $$DLLPATH/libgpg-error.dll _win_/freepops/libgpg-error.dll

dist-win-e-zip-step5:
	$(H)STRIP=`grep ^STRIP _win_/freepops-$(VERSION)/config|cut -d = -f 2`;\
		$$STRIP _win_/freepops/*.exe \
			_win_/freepops/*.dll \
			_win_/freepops/C/*.dll

	$(H)sed 's/\%FREEPOPSVERSION/$(VERSION)/' win/freepops.nsi.in > \
		_win_/freepops/freepops.nsi

	$(H)xpm2wico -f win/freepops-setup.xpm _win_/freepops/freepops-setup.ico
	$(H)xpm2wico -f win/freepops-remove.xpm _win_/freepops/freepops-remove.ico
	$(H)xpm2wico -f ../updater-ui/fltk/freepops-updater-fltk-32.xpm \
		_win_/freepops/freepops-updater.ico

	$(H)cd _win_/freepops/; makensis freepops.nsi
	
	$(H)mkdir ../dist-win || true
	$(H)mv _win_/freepops/FreePOPs-$(VERSION).exe ../dist-win
	
	# end of installer 

	$(H)cd _win_/freepops/; cp LUA/config.lua .
	
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

dist-deb-hacketch:
	$(H)cd _deb_/freepops-$(VERSION);\
		cp buildfactory/debian-etch/* debian/
		
dist-deb-hackbpo:
	$(H)cd _deb_/freepops-$(VERSION);\
		V=`head -n 1 debian/changelog | sed "s/.*(\([^)]*\)).*/\1/"`;\
		BPOR=bpo.1;\
		dch -D etch-backports -b -v $$V~$$BPOR backports.org release

dist-deb-hackubuntu:
	$(H)cd _deb_/freepops-$(VERSION);\
	sed -e "/#/d" -e "0,/^$$/{/^$$/d}" < buildfactory/debian/freepops.templates \
			> buildfactory/debian-ubuntu/freepops.templates
	$(H)cd _deb_/freepops-$(VERSION);\
		cp buildfactory/debian-ubuntu/* debian/

dist-deb-etch: deb-preamble dist-deb-hacketch dist-deb-real
dist-deb-sid: dist-deb
dist-deb-etch: dist-deb
dist-deb-ubuntu: deb-preamble dist-deb-hackubuntu dist-deb-real
	
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
	$(H)cd ../dist-deb/freepops/;\
		dpkg-scanpackages . /dev/null > Packages
	$(H)cd ../dist-deb/freepops/;\
		dpkg-scansources . /dev/null > Sources
	$(H)cd ../dist-deb/freepops/;gzip -f Packages Sources

	$(H)rm -rf _deb_

debian-dsc-etch: deb-preamble dist-deb-hacketch debian-dsc-real
debian-dsc-bpo: deb-preamble dist-deb-hacketch dist-deb-hackbpo debian-dsc-real
debian-dsc-etch: debian-dsc
debian-dsc-sid: debian-dsc
debian-dsc-ubuntu: deb-preamble dist-deb-hackubuntu debian-dsc-real

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

dist-osx: dist-osx-build dist-osx-finalyze

dist-osx-build: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _osx_
	$(H)[ -d _osx_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _osx_
	$(H)cd _osx_/freepops-$(VERSION);\
	  for X in i386 ppc; do \
	    make realclean; \
	    ./configure.sh osx-$$X -expat-lib-dir $$PWD/../../../../lib/lib/; \
	    $(MAKE) all; \
	    cp src/freepopsd.$$X* ..; \
	  done
	$(H)lipo -create -output _osx_/freepops-$(VERSION)/src/freepopsd \
		_osx_/freepopsd.*
	$(H)mkdir -p ../dist-osx/FreePOPs/doc
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua_unofficial
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua_updates/browser
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua_updates/lxp
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua_updates/soap
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/browser
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/lxp
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include/soap
	$(H)#mkdir -p ../dist-osx/FreePOPs/script
	$(H)cp osx/README-osx.txt ../dist-osx/FreePOPs/
	$(H)#cp osx/Install_resources/FreePOPs \
	       osx/Install_resources/StartupParameters.plist \
	       osx/Install_resources/freepopsd.plist \
	       osx/Install_resources/postflight \
		../dist-osx/FreePOPs/script
	$(H)cd _osx_/freepops-$(VERSION);\
		cp COPYING AUTHORS ChangeLog config.lua \
		../../../dist-osx/FreePOPs/
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
		cp *.lua \
		../../../../../../dist-osx/FreePOPs/modules/include/browser
	$(H)cd _osx_/freepops-$(VERSION)/modules/include/lxp;\
		cp *.lua ../../../../../../dist-osx/FreePOPs/modules/include/lxp
	$(H)cd _osx_/freepops-$(VERSION)/modules/include/soap;\
		cp *.lua \
		../../../../../../dist-osx/FreePOPs/modules/include/soap
	$(H)cat osx/ReadMe.en.txt > \
		osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog \
		>> osx/Install_resources/English.lproj/ReadMe.txt
	$(H)cat osx/ReadMe.it.txt > \
		osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)cat _osx_/freepops-$(VERSION)/ChangeLog \
		>> osx/Install_resources/Italian.lproj/ReadMe.txt
	$(H)rm -rf _osx_
	$(H)rm -rf ../dist-osx/FreePOPs.app
	$(H)mv ../dist-osx/FreePOPs ../dist-osx/FreePOPs.app

dist-osx-finalyze: ../dist-osx/FreePOPs.app
	$(H)$(MAKE) -C osx/popup-fltk/
	$(H)mkdir -p ../dist-osx/FreePOPs.app/Contents/MacOS
	$(H)mkdir -p ../dist-osx/FreePOPs.app/Contents/Resources
	$(H)cp osx/Info.plist ../dist-osx/FreePOPs.app/Contents
	$(H)cp osx/freepops.icns ../dist-osx/FreePOPs.app/Contents/Resources
	$(H)cp osx/popup-fltk/fmessage ../dist-osx/FreePOPs.app/Contents/MacOS/
	$(H)cp osx/start-stop-freepopsd \
		 ../dist-osx/FreePOPs.app/Contents/MacOS/
	$(H)$(MAKE) -C osx/popup-fltk/ clean
	$(H)cat osx/iceberg/FreePOPs/FreePOPs.packproj.in |\
		sed 's/@@VERSION@@/$(VERSION)/' > \
		osx/iceberg/FreePOPs/FreePOPs.packproj
	$(H)freeze osx/iceberg/FreePOPs/FreePOPs.packproj
	$(H)mv osx/iceberg/FreePOPs/build/freepops.pkg \
		../dist-osx/freepops-$(VERSION).pkg
	$(H)cd ../dist-osx; zip -r freepops-$(VERSION).pkg.zip \
		freepops-$(VERSION).pkg
	$(H)rm -rf ../dist-osx/freepops-$(VERSION).pkg
	$(H)rm -rf ../dist-osx/FreePOPs.app

dist-tgz: freepops-$(VERSION).tar.gz
	$(H)mkdir -p ../dist-tgz
	$(H)mv freepops-$(VERSION).tar.gz ../dist-tgz

freepops-$(VERSION).tar.gz: 
	$(H)cd ..;./configure.sh linux || true
	$(H)$(MAKE) -C .. tgz-dist
	$(H)mv ../dist-tgz/freepops-$(VERSION).tar.gz .
	$(H)rm -rf ../dist-tgz

#dist-tgz-msvc: freepops-$(VERSION).tar.gz
#	$(H)mkdir -p ../dist-tgz-msvc/
#	$(H)cp freepops-$(VERSION).tar.gz ../dist-tgz-msvc
#	$(H)cd ../dist-tgz-msvc; tar -xzf freepops-$(VERSION).tar.gz
#	$(H)cd ../dist-tgz-msvc; rm freepops-$(VERSION).tar.gz
#	$(H)cd ../dist-tgz-msvc; mv freepops-$(VERSION) freepops-msvc-$(VERSION)
#	$(H)cd ../dist-tgz-msvc/freepops-msvc-$(VERSION); \
#		./configure.sh win-msvc; make prepare
#	$(H)cd ../dist-tgz-msvc; \
#		zip -r freepops-msvc-$(VERSION).zip freepops-msvc-$(VERSION)/
#	$(H)cd ../dist-tgz-msvc; rm -rf freepops-msvc-$(VERSION)
	
include openbsd/Makefile
include slackware/Makefile
include gentoo/Makefile
include rpm/Makefile

# eof
