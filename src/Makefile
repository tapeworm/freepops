include $(CONFIG)

# TARGET and PREFIX are passed

H=@

#get the files ################################################
HDR=$(shell ls *.h  2> /dev/null)

SRC=$(shell ls *.c *.pkg 2> /dev/null)

OBJ=$(subst .c,.o,$(subst .pkg,.o,$(SRC)))

CDEPFILES=$(shell ls *.c 2> /dev/null)
ifneq ($(MAKECMDGOALS),clean)
ifneq "$(CDEPFILES)" "" 
	-include $(CDEPFILES:%.c=.%.d)
endif

LDEPFILES=$(shell ls *.pkg 2> /dev/null)
ifneq "$(LDEPFILES)" "" 
	-include $(LDEPFILES:%.pkg=.%.d)
endif
endif

#flags #######################################################
CFLAGS+= -I. -I../modules/include 

ifneq "$(FLTKUI)" ""
	CFLAGS+= -DFLTKUI
endif

ifneq "$(OS)" "Windows"
	CFLAGS+= $(shell curl-config --cflags)
endif

ifeq "$(OS)" "Windows"
	CFLAGS+= -DFREEPOPSLUA_PATH=\"lua/\"
	CFLAGS+= -DFREEPOPSLUA_CPATH=\"c/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UPDATES=\"lua_updates/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"lua_unofficial/\"
else
ifeq "$(OS)" "Darwin"
	CFLAGS+= -DFREEPOPSLUA_PATH=\"src/lua/\"
	CFLAGS+= -DFREEPOPSLUA_CPATH=\"c/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UPDATES=\"src/lua_updates/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"src/lua_unofficial/\"
else
ifeq "$(OS)" "Darwin-static"
	CFLAGS+= -DFREEPOPSLUA_PATH=\"src/lua/\"
	CFLAGS+= -DFREEPOPSLUA_CPATH=\"c/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UPDATES=\"src/lua_updates/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"src/lua_unofficial/\"
else
#ifeq "$(OS)" "BeOS"
#	CFLAGS+= -DFREEPOPSLUA_PATH=\"$HOME/config/settings/freepops/lua/\"
#	CFLAGS+= -DFREEPOPSLUA_PATH_UPDATES=\"$HOME/config/settings/freepops/lua_updates/\"
#	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"$HOME/config/settings/freepops/lua_unofficial/\"
#
#else
	CFLAGS+= -DFREEPOPSLUA_PATH=\"$(PREFIX)share/freepops/lua/\"
	CFLAGS+= -DFREEPOPSLUA_CPATH=\"$(PREFIX)lib/freepops/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UPDATES=\"/var/lib/freepops/lua_updates/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"/var/lib/freepops/lua_unofficial/\"
#endif
endif
endif
endif

ifeq "$(OS)" "Cygwin"
	CFLAGS+= -I/usr/include
endif

#CURL_LD_FLAGS=$(shell curl-config --libs || true)
ifeq "$(CURL_LD_FLAGS)" ""
	CURL_LD_FLAGS= -lcurl
endif

EXPAT_LD_FLAGS= -lexpat


BINARY=freepopsd$(EXEEXTENSION)

LIBS=		crypto_lua	\
		regularexp_lua	\
		stringhack_lua	\
                browser_lua     \
                getdate_lua     \
                dpipe_lua	\
                getdate         \
                $(LUACURL)      \
                support_lua     \
                mlex_lua        \
                log_lua         \
                serialize_lua   \
                session_lua     \
                pop3server_lua  \
                pop3server      \
		portablesocket_lua \
		base64_lua	\
                portablesocket  \
                session         \
                dictionary      \
                lock            \
                pid             \
                mlex            \
                list            \
                base64          \
                log             \
                regularexp      \
                oscompatibility \
		luabind		\
		$(LUAEXPAT)	\
		$(LUAFILESYSTEM) \
                luay            \
                $(LUALUA:%=%5.1) 
		
EXCLUDELIBS=	serialize_lua \
		browser_lua \
		support_lua
		
LIBSTOLINK=$(filter-out $(EXCLUDELIBS),$(LIBS))

LDFLAGS+=$(FORCE_LINK)
		
ifeq "$(OS)" "Windows"
  ifeq "$(SSL)" "openssl"
	LDFLAGS+= -L ../modules/lib \
		-Wl,-whole-archive -lwinsystray -Wl,-no-whole-archive\
		$(addprefix -l,$(LIBSTOLINK)) \
		-lregex -lm -l$(CURLNAME) -lmingw32 -lwsock32 \
			-lpthread -lexpat -lcrypto -lgdi32 -mwindows 
  else
	LDFLAGS+= -L ../modules/lib \
		-Wl,-whole-archive -lwinsystray -Wl,-no-whole-archive\
		$(addprefix -l,$(LIBSTOLINK)) \
		-lregex -lm -l$(CURLNAME) -lmingw32 -lwsock32 \
			-lpthread -lexpat -lgdi32 -mwindows -lgcrypt -lgpg-error
  endif
else
ifeq "$(OS)" "Darwin"
	LDFLAGS+=-L../modules/lib $(addprefix -l,$(LIBSTOLINK)) \
		-lgetopt -lm \
	 	-lpthread -L/usr/lib -L/sw/lib /sw/lib/libexpat.a -lcurl \
		-lcrypto -ldl -lssl -lcrypto -lz 
else
ifeq "$(OS)" "Darwin-static"
	OSXLIBDL=-ldl
	ifneq "$(shell find /usr/local/lib/ -iname libdl.a)" ""
	  OSXLIBDL=/usr/local/lib/libdl.a
	endif
	ifneq "$(shell find /sw/lib/ -iname libdl.a)" ""
	  OSXLIBDL=/sw/lib/libdl.a
	endif
	LDFLAGS+=-L../modules/lib $(addprefix -l,$(LIBSTOLINK)) \
		$(OSXLIBDL) /sw/lib/libcurl.a \
		/sw/lib/libssl.a /sw/lib/libcrypto.a /sw/lib/libexpat.a \
		-L/usr/lib -lgetopt -lm -lpthread -lz -bind_at_load -noprebind
else
ifeq "$(OS)" "OpenBSD"
	LIBSTOLINK+= getopt
	LDFLAGS+=-L../modules/lib $(addprefix -l,$(LIBSTOLINK)) -lm -pthread \
		$(CURL_LD_FLAGS) $(EXPAT_LD_FLAGS)
else
ifeq "$(OS)" "FreeBSD"
        LIBSTOLINK+= getopt     
        LDFLAGS+=-L../modules/lib $(addprefix -l,$(LIBSTOLINK)) -lm -pthread \
                $(CURL_LD_FLAGS) $(EXPAT_LD_FLAGS)
else
ifeq "$(OS)" "Solaris"
        LIBSTOLINK+= getopt     
        LDFLAGS+=-R$(PREFIX)/lib -L../modules/lib $(addprefix \
	        -l,$(LIBSTOLINK)) -lm $(CURL_LD_FLAGS) $(EXPAT_LD_FLAGS)
else
ifeq "$(OS)" "Cygwin"
	LDFLAGS+= -L ../modules/lib \
		$(addprefix -l,$(LIBSTOLINK)) -lregex -lm -lpthread -lcurl \
		-lwsock32 -lexpat -lgdi32 -lz -lssl -lcrypto -lcygwin
else
ifeq "$(OS)" "BeOS"
	LDFLAGS+=-L ../modules/lib $(addprefix -l,$(LIBSTOLINK)) \
		-ldl -lpthread $(CURL_LD_FLAGS) $(EXPAT_LD_FLAGS) \
		-lbe -lsocket -lbind
else
ifeq "$(SSL)" "openssl"
	LDFLAGS+=-L ../modules/lib $(addprefix -l,$(LIBSTOLINK))\
		-ldl -lm -lpthread -lcrypto -rdynamic \
		$(CURL_LD_FLAGS) $(EXPAT_LD_FLAGS)
else
	LDFLAGS+=-L ../modules/lib $(addprefix -l,$(LIBSTOLINK))\
		-ldl -lm -lpthread -lgcrypt -rdynamic \
		$(CURL_LD_FLAGS) $(EXPAT_LD_FLAGS)
endif
endif
endif
endif	
endif
endif
endif
endif	
endif

#rules ####################################################
all: $(CDEPFILES:%.c=.%.d) $(LDEPFILES:%.pkg=.%.d) $(BINARY)
	$(H)echo -n

clean:
	$(H)rm -f $(CDEPFILES:%.c=.%.d) $(OBJ)\
		$(LDEPFILES:%.pkg=.%.d) $(LDEPFILES:%.pkg=%.c) \
		$(LDEPFILES:%.pkg=%.h) $(BINARY) \
		lua_updates/* lua_unofficial/*

	
#############################################

$(BINARY): $(OBJ) $(addsuffix .a,$(addprefix ../modules/lib/lib,$(LIBS)))
	$(H)echo -n " linking "
#	$(H)$(RANLIB) ../modules/lib/libgetdate.a ../modules/lib/liblua.a
	$(H)$(RANLIB) $(addsuffix .a,$(addprefix ../modules/lib/lib,$(filter-out mlex_lua,$(LIBSTOLINK))))
ifeq "$(OS)" "Windows"
	mkdir libfp
	cp $(addsuffix .a,$(addprefix ../modules/lib/lib,$(LIBSTOLINK))) libfp
	cd libfp; for X in *.a; do ar x $$X; done
	cd libfp; $(DLLTOOL) -e ../exports.o -l ../libfp.lib *.o
	$(CC) -o libfp.dll -shared exports.o libfp/*o `echo $(LDFLAGS)|sed 's/-l[^ ]*//'`
	$(CC) -o $(BINARY) $(OBJ) -L. -lfp -lwsock32 -l$(CURLNAME)
else
	$(H)$(CC) -o $(BINARY) $(OBJ) $(LDFLAGS) 
endif
	$(H)echo "$(BINARY)"
	$(H)echo $(DYNLIBS)
	
.%.d:%.c
	$(H)echo " building dep for $<"
	$(H)$(CC) $(CFLAGS) -MM $< > $@;

.%.d:%.pkg
	$(H)echo " building dep for $<"
	$(H)echo "$(subst .pkg,.o,$<) : $< " > $@ 

%.o:%.pkg
	$(H)echo -n " processing $< -> "
	$(H)$(PREFIX)/bin/tolua++ -S -H $(subst .pkg,.h,$<) -o $(subst .pkg,.c,$<) $<
	$(H)echo "$(subst .pkg,.c,$<)"
	$(H)echo -n " compiling $(subst .pkg,.c,$<) -> "
	$(H)$(CC) $(CFLAGS) -c $(subst .pkg,.c,$<) || \
		(mv -f $(subst .pkg,.c,$<) $(subst .pkg,.c,$<)~;exit 1)
	$(H)mv -f $(subst .pkg,.c,$<) $(subst .pkg,.c,$<)~ 
	$(H)echo "$@"

%.o:%.c
	$(H)echo -n " compiling $< -> "
	$(H)$(CC) $(CFLAGS) -c $<
	$(H)echo "$@"

	
.PHONY:all	

