include config

#
# WHERE=/usr/local/
# WHERE is now set by configure.sh
PREFIX=$(DESTDIR)$(WHERE)
VERSION=$(shell grep "\#define VERSION" config.h | cut -d \" -f 2)
MAKEFLAGS+=--no-print-directory
PWD=$(shell pwd)

H=@

#>----------------------------------------------------------------------------<#

help:
	$(H)#ln -s buildfactory/debian . 1>/dev/null 2>/dev/null || true
	$(H)echo "Targets are:"
	$(H)echo "  all          - build it (remember to ./configure.sh first)"
	$(H)echo "  clean        - clean the source tree"
	$(H)echo "  distclean    - remove also the dist-* distributions"
	$(H)echo "  realclean    - clean and be ready for building to another arch"
	$(H)echo "  doc          - create developers documentation"
	$(H)echo "  install      - install it (linux/unix distribution independent)"
	$(H)echo "  uninstall    - uninstall it (linux/unix distribution independent)"
	$(H)echo "  buildfactory - build all distributions"
	$(H)echo
	$(H)echo "Default is all"
	$(H)sleep 2
	$(H)$(MAKE) all
	

all : modules src 
	$(H)echo -n

clean: 
	$(H)#ln -s buildfactory/debian . 2>/dev/null || true
	$(H)echo "cleaning freepopsd"
	$(H)$(MAKE) -C src clean CONFIG=$(PWD)/config || true
	$(H)$(MAKE) -C modules clean CONFIG=$(PWD)/config || true
	$(H)$(MAKE) -C buildfactory clean CONFIG=$(PWD)/config || true
	$(H)rm -f core* *-stamp dh_clean
	$(H)rm -f doc/manual.ps doc/manual.pdf\
		doc/manual-it.ps doc/manual-it.pdf
distclean: clean
	$(H)rm -fr dist-*
	$(H)$(MAKE) -C doc/manual clean

realclean: distclean
	$(H)rm -f config
	
doc: manual
	$(H)$(MAKE) -C modules doc CONFIG=$(PWD)/config

manual: doc/manual.pdf doc/manual-it.pdf
	
install: all
	$(H)mkdir -p $(PREFIX)
	$(H)mkdir -p $(PREFIX)bin
	$(H)mkdir -p $(PREFIX)share/freepops/lua/
	$(H)mkdir -p $(PREFIX)share/freepops/lua_unofficial/
	$(H)mkdir -p $(PREFIX)share/doc/freepops/
	$(H)mkdir -p $(PREFIX)share/man/man1/
	$(H)mkdir -p $(DESTDIR)/etc/freepops
	$(H)cp src/freepopsd$(EXECSUFFIX) $(PREFIX)bin
	$(H)cp src/lua/*.lua modules/include/*.lua config.lua \
		$(PREFIX)share/freepops/lua/
	$(H)cp doc/freepopsd.1  $(PREFIX)share/man/man1/
	$(H)cp doc/manual*.pdf  $(PREFIX)share/doc/freepops/ 2>/dev/null ||\
		cp doc/MANUAL.txt  $(PREFIX)share/doc/freepops/ 2>/dev/null || \
		true
	$(H)cp config.lua $(DESTDIR)/etc/freepops/

uninstall:
	$(H)rm -f $(DESTDIR)/etc/freepops/config.lua
	$(H)rm -f $(PREFIX)share/doc/freepops/manual.ps
	$(H)rm -f $(PREFIX)share/doc/freepops/manual-it.ps
	$(H)rm -f $(PREFIX)share/man/man1/freepopsd.1
	$(H)rm -f $(PREFIX)share/freepops/lua/*
	$(H)rm -f $(PREFIX)bin/freepopsd$(EXECSUFFIX)
	$(H)rmdir $(DESTDIR)/etc/freepops
	$(H)rmdir $(PREFIX)share/man/man1/
	$(H)rmdir $(PREFIX)share/doc/freepops/
	$(H)rmdir $(PREFIX)share/freepops/lua/
	$(H)rmdir $(PREFIX)share/freepops/
	$(H)-rmdir $(PREFIX)bin
	$(H)-rmdir $(PREFIX)

tgz-dist: 
	$(H)#ln -s buildfactory/debian . 2>/dev/null || true
	$(H)CUR=`pwd`;\
		BASE=`basename $$CUR`;\
		cd ..;\
		tar -czf freepops.tgz $$BASE;\
		cd $$BASE;\
		[ -d dist-tgz ] || mkdir dist-tgz;\
		mv ../freepops.tgz dist-tgz/;\
		cd dist-tgz/;\
		tar -xzf freepops.tgz;\
		rm freepops.tgz;\
		cd $$BASE; $(MAKE) realclean; cd ..;\
		find $$BASE -name CVS -exec rm -fr \{\} \; 2>/dev/null;\
		echo "removing non-free doc files (like RFCs and contracts)";\
		cd $$BASE;\
		for X in doc/rfc/rfc*.txt; do \
			echo http://www.ietf.org/rfc/`basename $$X` >> \
			doc/RFCs.txt;\
		done; \
		rm -rf doc/rfc/;\
		rm -rf doc/contracts/;\
		cd ..;\
		mv $$BASE freepops-$(VERSION) || true;\
		tar -cf freepops-$(VERSION).tar freepops-$(VERSION);\
		gzip -9 freepops-$(VERSION).tar;\
		rm -r freepops-$(VERSION)
	
buildfactory:
	$(H)#ln -s buildfactory/debian . 2>/dev/null || true
	$(H)$(MAKE) -C buildfactory all CONFIG=$(PWD)/config
	
#>----------------------------------------------------------------------------<#

modules: config
	$(H)#ln -s buildfactory/debian . 2>/dev/null || true
	$(H)$(MAKE) -C modules all CONFIG="$(PWD)/config"
	
src: config
	$(H)echo "building freepopsd"
	$(H)$(MAKE) -C src all CONFIG="$(PWD)/config" PREFIX="$(PREFIX)" \
		FORCE_LINK="$(FORCE_LINK)"

doc/manual.pdf doc/manual-it.pdf: doc/manual/manual.tex doc/manual/manual-it.tex
	$(H)$(MAKE) -C doc/manual/

config:
	$(H)echo
	$(H)echo "Before running $(MAKE) you have to configure the building system"
	$(H)echo "running './configure'. Type './configure help' for more infos"
	$(H)echo
	$(H)exit 1



.PHONY: modules src doc buildfactory



