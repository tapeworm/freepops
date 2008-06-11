include config

#
# WHERE=/usr/local/
# WHERE is now set by configure.sh
PREFIX=$(DESTDIR)$(WHERE)
VERSION=$(shell grep "\#define VERSION" config.h | cut -d \" -f 2)
MAKEFLAGS+=--no-print-directory
PWD=$(shell pwd)
GMO=$(shell ls "$(PWD)/updater-ui/fltk/po" | grep ".gmo")
LANGDIR=$(shell ls -d "$(PREFIX)share/locale/"*"/" | sed -e "s/\/*$$//g" -e "s/ /$$/g" -e "s/.*\///g")

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
	$(H)echo "  manual       - create user/developers manual"
	$(H)echo "  install      - install it (linux/unix distribution independent)"
	$(H)echo "  uninstall    - uninstall it (linux/unix distribution independent)"
	$(H)echo "  buildfactory - build all distributions"
	$(H)echo
	$(H)echo "Default is all"
	$(H)sleep 2
	$(H)$(MAKE) all
	

all : modules src updater-ui-fltk
	$(H)echo -n

prepare:
	$(H)make -C modules/ prepare CONFIG=$(PWD)/config

clean: 
	$(H)#ln -s buildfactory/debian . 2>/dev/null || true
	$(H)echo "cleaning freepopsd"
	$(H)$(MAKE) -C src clean CONFIG=$(PWD)/config || true
	$(H)$(MAKE) -C modules clean CONFIG=$(PWD)/config || true
	$(H)$(MAKE) -C buildfactory clean CONFIG=$(PWD)/config || true
	$(H)rm -f core* *-stamp dh_clean
	$(H)rm -f doc/manual.ps doc/manual.pdf\
		doc/manual-it.ps doc/manual-it.pdf
	$(H)$(MAKE) -C updater-ui/fltk clean CONFIG=$(PWD)/config || true

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
	$(H)mkdir -p $(DESTDIR)var/lib/freepops/lua_unofficial/
	$(H)mkdir -p $(DESTDIR)var/lib/freepops/lua_updates/
	$(H)mkdir -p $(PREFIX)share/doc/freepops/
	$(H)mkdir -p $(PREFIX)share/man/man1/
	$(H)mkdir -p $(DESTDIR)etc/freepops
	$(H)if [ ! -z "$(FLTKUI)" ]; then \
		mkdir -p $(PREFIX)lib/freepops/; \
		cp updater-ui/fltk/updater_fltk$(SHAREDEXTENSION) \
			$(PREFIX)lib/freepops/; \
		cp updater-ui/fltk/freepops-updater-fltk $(PREFIX)bin; \
		for gmo in $(GMO); do \
			lang=`echo $$gmo | sed -e "s/\.gmo//g"`; \
			mkdir -p $(PREFIX)share/locale/$$lang/LC_MESSAGES/; \
			cp updater-ui/fltk/po/$$lang.gmo \
				$(PREFIX)share/locale/$$lang/LC_MESSAGES/updater_fltk.mo; \
		done; \
	fi
	$(H)cp updater-ui/dialog/freepops-updater-dialog $(PREFIX)bin
	$(H)cp updater-ui/zenity/freepops-updater-zenity $(PREFIX)bin
	$(H)chmod a+rx $(PREFIX)bin/freepops-updater-dialog
	$(H)cp src/freepopsd$(EXEEXTENSION) $(PREFIX)bin
	$(H)cp src/lua/*.lua modules/include/*.lua config.lua \
		$(PREFIX)share/freepops/lua/
	# keep these in sync with win32 installer
	$(H)mkdir -p $(DESTDIR)var/lib/freepops/lua_updates/lxp
	$(H)mkdir -p $(DESTDIR)var/lib/freepops/lua_updates/browser
	$(H)mkdir -p $(DESTDIR)var/lib/freepops/lua_updates/soap
	$(H)mkdir -p $(PREFIX)share/freepops/lua/lxp/
	$(H)mkdir -p $(PREFIX)share/freepops/lua/browser/
	$(H)mkdir -p $(PREFIX)share/freepops/lua/soap/
	$(H)if [ -d modules/include/lxp/ ]; then \
		for X in modules/include/lxp/*.lua; do \
			cp $$X $(PREFIX)share/freepops/lua/lxp/; \
		done; \
	fi
	$(H)if [ -d modules/include/browser/ ]; then \
		for X in modules/include/browser/*.lua; do \
			cp $$X $(PREFIX)share/freepops/lua/browser/; \
		done; \
	fi	
	$(H)if [ -d modules/include/soap/ ]; then \
		for X in modules/include/soap/*.lua; do \
			cp $$X $(PREFIX)share/freepops/lua/soap/; \
		done; \
	fi
	$(H)cp doc/freepopsd.1  $(PREFIX)share/man/man1/
	$(H)cp doc/freepops-updater-dialog.1  $(PREFIX)share/man/man1/
	$(H)cp doc/freepops-updater-zenity.1  $(PREFIX)share/man/man1/
	$(H)if [ ! -z "$(FLTKUI)" ]; then \
		cp doc/freepops-updater-fltk.1  $(PREFIX)share/man/man1/;\
	fi
	$(H)cp doc/manual*.pdf  $(PREFIX)share/doc/freepops/ || true
	$(H)cp doc/MANUAL.txt  $(PREFIX)share/doc/freepops/ || true
	$(H)cp config.lua $(DESTDIR)etc/freepops/

uninstall:
	$(H)rm -f $(DESTDIR)etc/freepops/config.lua
	$(H)rm -f $(PREFIX)share/doc/freepops/manual.ps
	$(H)rm -f $(PREFIX)share/doc/freepops/manual-it.ps
	$(H)rm -f $(PREFIX)share/man/man1/freepopsd.1
	$(H)rm -f $(PREFIX)share/freepops/lua/*
	$(H)rm -f $(DESTDIR)var/lib/freepops/lua_unofficial/*
	$(H)rm -f $(DESTDIR)var/lib/freepops/lua_updates/*
	$(H)rm -f $(DESTDIR)var/lib/freepops/lua_updates/*/*
	$(H)rm -f $(PREFIX)lib/freepops/*
	$(H)rm -f $(PREFIX)bin/freepopsd$(EXEEXTENSION)
	$(H)rmdir $(DESTDIR)etc/freepops
	$(H)rmdir $(PREFIX)share/man/man1/
	$(H)rmdir $(PREFIX)share/doc/freepops/
	$(H)rmdir $(PREFIX)share/freepops/lua/
	$(H)rmdir $(DESTDIR)var/lib/freepops/lua_unofficial/
	$(H)rmdir $(DESTDIR)var/lib/freepops/lua_updates/*/
	$(H)rmdir $(DESTDIR)var/lib/freepops/lua_updates/
	$(H)rmdir $(PREFIX)lib/freepops/
	$(H)rmdir $(PREFIX)share/freepops/
	$(H)-rmdir $(PREFIX)bin
	$(H)-rmdir $(PREFIX)
	$(H)for lang in $(LANGIDIR); do \
		rm -f $(PREFIX)share/locale/$$lang/LC_MESSAGES/updater_fltk.mo; \
	done

tgz-dist: 
	$(H)#ln -s buildfactory/debian . 2>/dev/null || true
	$(H)CUR=`pwd`;\
		BASE=`basename $$CUR`;\
		cd ..;\
		$(TAR) -czf freepops.tgz $$BASE;\
		cd $$BASE;\
		[ -d dist-tgz ] || mkdir dist-tgz;\
		mv ../freepops.tgz dist-tgz/;\
		cd dist-tgz/;\
		$(TAR) -xzf freepops.tgz;\
		rm freepops.tgz;\
		cd $$BASE; $(MAKE) realclean; cd ..;\
		find $$BASE -name CVS -exec rm -fr \{\} \; 2>/dev/null;\
		find $$BASE -name .svn -exec rm -fr \{\} \; 2>/dev/null;\
		echo "removing non-free doc files (like RFCs and contracts)";\
		cd $$BASE;\
		for X in doc/rfc/rfc*.txt; do \
			echo http://www.ietf.org/rfc/`basename $$X` >> \
			doc/RFCs.txt;\
		done; \
		rm -rf doc/rfc/;\
		rm -rf doc/contracts/;\
		chmod -R a+r *;\
		cd ..;\
		mv $$BASE freepops-$(VERSION) || true;\
		$(TAR) -cf freepops-$(VERSION).tar freepops-$(VERSION);\
		gzip -f9 freepops-$(VERSION).tar;\
		rm -rf freepops-$(VERSION)
	
buildfactory:
	$(H)$(MAKE) -C buildfactory all CONFIG=$(PWD)/config
	
#>----------------------------------------------------------------------------<#

modules: config
	$(H)$(MAKE) -C modules all CONFIG="$(PWD)/config"
	
src: config
	$(H)echo "building freepopsd"
	$(H)$(MAKE) -C src all CONFIG="$(PWD)/config" PREFIX="$(PREFIX)" \
		FORCE_LINK="$(FORCE_LINK)"

updater-ui-fltk:config
ifneq "$(FLTKUI)" ""
	$(H)echo "building updater-ui/fltk"
	$(H)$(MAKE) -C updater-ui/fltk all CONFIG="$(PWD)/config"
else
	$(H)echo -n
endif

doc/manual.pdf doc/manual-it.pdf: doc/manual/manual.tex doc/manual/manual-it.tex
	$(H)$(MAKE) -C doc/manual/

config:
	$(H)echo
	$(H)echo "Before running $(MAKE) you have to configure the building system"
	$(H)echo "running './configure'. Type './configure help' for more infos"
	$(H)echo
	$(H)exit 1



.PHONY: modules src doc buildfactory updater-ui-fktl



