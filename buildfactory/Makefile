include $(CONFIG)

VERSION=$(shell grep "\#define VERSION" ../config.h | cut -d \" -f 2)

H=@
#H=

help:
	$(H)echo
	$(H)echo "here we build all the distributed packages"
	$(H)echo
	$(H)echo "Targets are: all dist-{win,deb,rpm,gen,tgz}"
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
		make all;
	$(H)cp _win_/freepops-$(VERSION)/src/freepopsd.exe _win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/modules/lib/libpthread.dll \
		_win_/freepops
	$(H)cp _win_/freepops-$(VERSION)/src/lua/*.lua _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/modules/include/*.lua _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/config.lua _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/doc/manual.pdf _win_/freepops/
	$(H)cp _win_/freepops-$(VERSION)/doc/manual-it.pdf _win_/freepops/

	$(H)cp _win_/freepops-$(VERSION)/COPYING _win_/freepops/COPYING.txt
	$(H)cp _win_/freepops-$(VERSION)/ChangeLog _win_/freepops/ChangeLog.txt

	$(H)unix2dos _win_/freepops/COPYING.txt
	$(H)unix2dos _win_/freepops/ChangeLog.txt

	$(H)$(STRIP) _win_/freepops/*.exe _win_/freepops/*.dll

	$(H)sed 's/\%FREEPOPSVERSION/$(VERSION)/' freepops.nsi.in > \
		_win_/freepops/freepops.nsi

	$(H)xpm2wico -f freepops-setup.xpm _win_/freepops/freepops-setup.ico
	$(H)xpm2wico -f freepops-remove.xpm _win_/freepops/freepops-remove.ico

	$(H)cd _win_/freepops/;\
		wine /usr/local/NSIS/makensis.exe freepops.nsi
	
	$(H)mkdir ../dist-win || true
	$(H)mv _win_/freepops/FreePOPs-$(VERSION).exe ../dist-win
	
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
	@cp freepopsd.ebuild.gz \
		../dist-gen/freepopsd-$(VERSION).ebuild.gz

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

freepops-$(VERSION).tar.gz: 
	$(H)cd ..;./configure.sh linux || true
	$(H)make -C .. tgz-dist
	$(H)cp ../dist-tgz/freepops-$(VERSION).tar.gz .
	
	
