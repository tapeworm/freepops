include config

WHERE=/usr/local/
PREFIX=$(DESTDIR)$(WHERE)
VERSION=$(shell grep "\#define VERSION" config.h | cut -d \" -f 2)

#H=
H=@

#>----------------------------------------------------------------------------<#

help:
	$(H)ln -s buildfactory/debian . 2>/dev/null || true
	$(H)echo "Targets are:"
	$(H)echo "  all          - build it (remember to ./configure.sh first)"
	$(H)echo "  clean        - clean the source tree"
	$(H)echo "  distclean    - remove also the dist-* distributions"
	$(H)echo "  realclean    - clean and be ready for building to another arch"
	$(H)echo "  doc          - createdevelopers documentation"
	$(H)echo "  install      - install it"
	$(H)echo "  buildfactory - build all distributions"
	$(H)echo
	$(H)echo "Default is all"
	$(H)sleep 2
	$(H)make all
	

all : modules src

clean: 
	$(H)make -C src clean CONFIG=$$PWD/config || true
	$(H)make -C modules clean CONFIG=$$PWD/config || true
	$(H)make -C buildfactory clean CONFIG=$$PWD/config || true
	$(H)rm -f core* *-stamp dh_clean

distclean: clean
	$(H)rm -fr dist-*

realclean: distclean
	$(H)rm -f config
	
doc:
	$(H)make -C modules doc CONFIG=$$PWD/config

install: all
	$(H)mkdir -p $(PREFIX)
	$(H)mkdir -p $(PREFIX)bin
	$(H)mkdir -p $(PREFIX)share/freepops/lua/
	$(H)mkdir -p $(PREFIX)share/man/man1/
	$(H)mkdir -p $(DESTDIR)/etc/freepops
	$(H)cp src/freepopsd$(EXECSUFFIX) $(PREFIX)bin
	$(H)cp src/lua/*.lua modules/include/*.lua config.lua \
		$(PREFIX)share/freepops/lua/
	$(H)cp doc/freepopsd.1  $(PREFIX)share/man/man1/
	$(H)cp config.lua $(DESTDIR)/etc/freepops/

tgz-dist: 
	$(H)cd ..;\
		tar -czf freepops.tgz freepops
	$(H)[ -d dist-tgz ] || mkdir dist-tgz;\
		mv ../freepops.tgz dist-tgz/
	$(H)cd dist-tgz/;\
		tar -xzf freepops.tgz;\
		rm freepops.tgz;\
		cd freepops; make realclean;cd ..;\
		find freepops -name CVS -exec rm -r \{\} \; 2>/dev/null;\
		mv freepops freepops-$(VERSION);\
		tar -cf freepops-$(VERSION).tar freepops-$(VERSION);\
		gzip -9 freepops-$(VERSION).tar;\
		rm -r freepops-$(VERSION)
	
buildfactory:
	$(H)make -C buildfactory all CONFIG=$$PWD/config
	
#>----------------------------------------------------------------------------<#

modules: config
	$(H)make -C modules all CONFIG=$$PWD/config
	
src: config
	$(H)make -C src all CONFIG=$$PWD/config PREFIX=$(PREFIX)


config:
	$(H)echo
	$(H)echo "Before running make you have to configure the building system"
	$(H)echo "running './configure'. Type './configure help' for more infos"
	$(H)echo
	$(H)exit 1



.PHONY: modules src doc buildfactory



