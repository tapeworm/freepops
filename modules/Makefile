include $(CONFIG)
include modules

PWD=$(shell pwd)

H=@

MODULES=$(MODULES-$(OS)-pre) $(MODULES-Common) $(MODULES-$(OS)-post)

PRESET=	$(MAKE) -C src/ all
	
FORALL=	for X in $(MODULES); do						\
		echo "$$NAME $$X";					\
		$(MAKE) -C src/$$X $$ACTION 				\
			TARGET=`echo $$X | cut -d "-" -f 1` 		\
			PREFIX=$(PWD)					\
			CONFIG=$(CONFIG);				\
		if test ! $$? -eq 0 ; then break; fi ;			\
	done

########################################################################

all: src/config
	$(H)cd include/;ln -s ../../config.h . 1>/dev/null 2>/dev/null|| true
	$(H)ACTION="all";\
	NAME="building";\
	$(FORALL)

clean: src/config
	$(H)ACTION="clean";\
	NAME="cleaning";\
	$(FORALL)
	$(H)rm -f lib/* bin/* include/* src/config config 2>/dev/null || true
	$(H)rm -fr  bin/luafiles/ || true
	$(H)rm -fr html html_lua
	$(H)$(MAKE) -C src clean

doc: all
	$(H)doxygen
	$(H)mkdir html_lua 2> /dev/null || true
	$(H)find src -name \*.luadoc -exec cp \{\} $(PWD)/html_lua/ \;
	$(H)cd $(PWD)/html_lua/;\
		for X in *.luadoc ; do\
			mv $$X `basename $$X | \
				sed s/\.luadoc/_luadoc.lua/`;\
		done
	$(H)bin/luadoc  \
		$(PWD)/html_lua/*_luadoc.lua \
		$(PWD)/include/*.lua -d $(PWD)/html_lua/
	$(H)rm $(PWD)/html_lua/*_luadoc.lua
	

#########################################################################

src/config:
	$(H)$(PRESET)

