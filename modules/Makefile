include $(CONFIG)
include modules


#H=@
H=

MODULES=$(MODULES-$(OS)-pre) $(MODULES-Common) $(MODULES-$(OS)-post)

PRESET=	make -C src/ all
	
FORALL=	for X in $(MODULES); do						\
		make -C src/$$X $$ACTION 				\
			TARGET=`echo $$X | cut -d "-" -f 1` 		\
			PREFIX=$$PWD					\
			CONFIG=$(CONFIG);				\
		if test ! $$? -eq 0 ; then break; fi ;			\
	done

########################################################################

all: src/config
	$(H)cd include/;ln -s ../../config.h . || true
	$(H)ACTION="all";\
	$(FORALL)

clean: src/config
	$(H)ACTION="clean";\
	$(FORALL)
	$(H)rm -f lib/* bin/* include/* src/config config || true
	$(H)rm -fr  bin/luafiles/ || true
	$(H)rm -fr html html_lua
	$(H)make -C src clean

doc: all
	$(H)doxygen
	$(H)mkdir html_lua 2> /dev/null || true
	$(H)find src -name \*_lua.pkg -exec bin/pkg2luadoc \{\} \;
	$(H)FILES=`find src -name \*_lua.pkg.lua`;\
		for X in $$FILES ; do \
		mv $$X $$PWD/html_lua/`basename $$X | \
			sed s/_lua\.pkg\.lua/_lua_pkg.lua/` ; done
	$(H)find src -name \*_lua.luadoc -exec cp \{\} $$PWD/html_lua/ \;
	$(H)cd $$PWD/html_lua/;\
		for X in *.luadoc ; do\
			mv $$X `basename $$X | \
				sed s/_lua\.luadoc/_lua_luadoc.lua/`;\
		done
	$(H)bin/luadoc $$PWD/html_lua/*_lua_pkg.lua \
		$$PWD/html_lua/*_lua_luadoc.lua \
		$$PWD/include/*.lua -d $$PWD/html_lua/
	$(H)rm $$PWD/html_lua/*_lua_pkg.lua $$PWD/html_lua/*_lua_luadoc.lua
	

#########################################################################

src/config:
	$(H)$(PRESET)

