include $(CONFIG)
include modules
include src/subscribed

PWD=$(shell pwd)

H=@

MODULES=$(MODULES-$(OS)-pre) $(MODULES-Common) $(MODULES-$(OS)-post)

PRESET=	$(MAKE) -C src/ all
	
FORALL=	for X in $$MODULES; do						\
		echo "$$NAME $$X";					\
		$(MAKE) -C src/$$X $$ACTION 				\
			TARGET=`echo $$X | cut -d "-" -f 1` 		\
			PREFIX=$(PWD)					\
			CONFIG=$(CONFIG);				\
		if test ! $$? -eq 0 ; then break; fi ;			\
	done

########################################################################

include/config.h:
	$(H)cd include/;ln -s ../../config.h . 1>/dev/null 2>/dev/null|| true

prepare: src/config include/config.h
	$(H)ACTION="prepare";\
	NAME="building";\
	MODULES="$(MODULES)";\
	$(FORALL)

all: src/config include/config.h
	$(H)ACTION="all";\
	NAME="building";\
	MODULES="$(MODULES)";\
	$(FORALL)

clean: src/config
	$(H)ACTION="clean";\
	NAME="cleaning";\
	MODULES="$(MK_TEMPLATE) $(MK_TEMPL_CTRIB)";\
	$(FORALL)
	$(H)rm -f lib/* bin/* include/* src/config config 2>/dev/null || true
	$(H)rm -fr  bin/luafiles/ || true
	$(H)rm -fr html html_lua
	$(H)$(MAKE) -C src clean
	$(H)for D in include/*/; do\
		N=`ls $$D/*.lua $$D/*/*.lua $$D/*/*/*.lua 2>/dev/null | wc -l`;\
		if [ $$N -gt 0 ]; then \
			rm -fr $$D;\
		fi;\
	done

doc: all
	$(H)doxygen
	$(H)rm -rf html_lua
	$(H)mkdir html_lua 2> /dev/null || true
	$(H)find src -name \*.luadoc -exec cp \{\} $(PWD)/html_lua/ \;
	$(H)cp include/*.lua include/*/*.lua ../src/lua/freepops.lua html_lua/
	$(H)cd html_lua; luadoc --nomodules *.lua *.luadoc
	$(H)rm html_lua/*.luadoc html_lua/*.lua
	

#########################################################################

src/config:
	$(H)$(PRESET)

