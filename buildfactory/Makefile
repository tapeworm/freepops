include $(CONFIG)

VERSION=$(shell grep "\#define VERSION" ../config.h | cut -d \" -f 2)

H=@

help:
	$(H)echo
	$(H)echo "here we build all the distributed packages"
	$(H)echo
	$(H)echo "Targets are: all dist-{osx,win,deb,rpm,gen,tgz}"
	$(H)echo

all: dist-deb dist-rpm dist-win dist-gen

clean:
	$(H)rm -rf _*_ freepops-[0-9\.]*.tar.gz

dist-win: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _win_/freepops
	$(H)[ -d _win_/freepops-$(VERSION) ] || \
		tar -xzf freepops-$(VERSION).tar.gz -C _win_
	$(H)cd _win_/freepops-$(VERSION);\
		./configure.sh win;\
		$(MAKE) all;
	$(H)cp _win_/freepops-$(VERSION)/src/freepopsd.exe _win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/modules/lib/libpthread.dll \
		_win_/freepops
	$(H)cp /usr/local/cross-tools/i386-mingw32msvc/bin/libcurl_nossl-3.dll \
		_win_/freepops/libcurl-3.dll
	$(H)cp _win_/freepops-$(VERSION)/src/lua/*.lua _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/modules/include/*.lua _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/config.lua _win_/freepops/
	$(H)#cp _win_/freepops-$(VERSION)/doc/manual.pdf _win_/freepops/
	$(H)#cp _win_/freepops-$(VERSION)/doc/manual-it.pdf _win_/freepops/

	$(H)cp _win_/freepops-$(VERSION)/COPYING _win_/freepops/COPYING.txt
	$(H)cp _win_/freepops-$(VERSION)/ChangeLog _win_/freepops/ChangeLog.txt

	$(H)unix2dos _win_/freepops/COPYING.txt
	$(H)unix2dos _win_/freepops/ChangeLog.txt

	$(H)/usr/local/cross-tools/i386-mingw32msvc/bin/strip \
		_win_/freepops/*.exe _win_/freepops/*.dll

	$(H)sed 's/\%FREEPOPSVERSION/$(VERSION)/' freepops.nsi.in > \
		_win_/freepops/freepops.nsi

	$(H)xpm2wico -f freepops-setup.xpm _win_/freepops/freepops-setup.ico
	$(H)xpm2wico -f freepops-remove.xpm _win_/freepops/freepops-remove.ico

	$(H)cd _win_/freepops/;\
		wine /usr/local/NSIS/$(MAKE)nsis.exe freepops.nsi
	
	$(H)mkdir ../dist-win || true
	$(H)mv _win_/freepops/FreePOPs-$(VERSION).exe ../dist-win
	
	$(H)cp /usr/local/cross-tools/i386-mingw32msvc/bin/libcurl-3.dll \
		_win_/freepops/libcurl-3.dll
	$(H)/usr/local/cross-tools/i386-mingw32msvc/bin/strip \
		_win_/freepops/*.exe _win_/freepops/*.dll
	$(H)cd _win_/freepops/;\
		wine /usr/local/NSIS/$(MAKE)nsis.exe freepops.nsi
	$(H)mv _win_/freepops/FreePOPs-$(VERSION).exe \
		../dist-win/FreePOPs-$(VERSION)-SSL.exe
	
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
	$(H)mkdir -p _deb_/freepops
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

dist-osx:
	$(H)cd ..;./configure.sh osx || true
	$(H)cd ..;$(MAKE) all CONFIG=../config
	$(H)mkdir -p ../dist-osx/FreePOPs/doc
	$(H)mkdir -p ../dist-osx/FreePOPs/src/lua
	$(H)mkdir -p ../dist-osx/FreePOPs/modules/include
	$(H)cp README-osx.txt ../dist-osx/FreePOPs/
	$(H)cd ..;cp COPYING AUTHORS ChangeLog config.lua dist-osx/FreePOPs/
	$(H)cd ../doc;cp LP-FP-HOWTO.txt MANUAL ../dist-osx/FreePOPs/doc/
	$(H)cd ../src;strip freepopsd;cp freepopsd ../dist-osx/FreePOPs/src/
	$(H)cd ../dist-osx/FreePOPs/;ln -s src/freepopsd freepopsd
	$(H)cd ../src/lua;cp *.lua ../../dist-osx/FreePOPs/src/lua
	$(H)cd ../modules/include;cp *.lua ../../dist-osx/FreePOPs/modules/include
	$(H)cat ../CHANGELOG >> Install_resources/English.lproj/ReadMe.txt
	$(H)cat ../CHANGELOG >> Install_resources/Italian.lproj/ReadMe.txt

freepops-$(VERSION).tar.gz: 
	$(H)cd ..;./configure.sh linux || true
	$(H)$(MAKE) -C .. tgz-dist
	$(H)cp ../dist-tgz/freepops-$(VERSION).tar.gz .
	
	
