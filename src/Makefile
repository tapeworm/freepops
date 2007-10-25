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
else
ifeq "$(OS)" "Darwin"
	CFLAGS+= -DFREEPOPSLUA_PATH=\"src/lua/\"
	CFLAGS+= -DFREEPOPSLUA_CPATH=\"c/\"
else
ifeq "$(OS)" "Darwin-static"
	CFLAGS+= -DFREEPOPSLUA_PATH=\"src/lua/\"
	CFLAGS+= -DFREEPOPSLUA_CPATH=\"c/\"
else
#ifeq "$(OS)" "BeOS"
#	CFLAGS+= -DFREEPOPSLUA_PATH=\"$HOME/config/settings/freepops/lua/\"
#	CFLAGS+= -DFREEPOPSLUA_PATH=\"$HOME/config/settings/freepops/c/\"
#else
	CFLAGS+= -DFREEPOPSLUA_PATH=\"$(PREFIX)share/freepops/lua/\"
	CFLAGS+= -DFREEPOPSLUA_CPATH=\"$(PREFIX)lib/freepops/\"
#endif
endif
endif
endif

ifeq "$(OS)" "Cygwin"
	CFLAGS+= -I/usr/include
endif

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
                stats_lua        \
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
		-lregex -lm -l$(CURLNAME) -lcrypto -lmingw32 -lwsock32 \
			-lpthread -lexpat -lgdi32 -mwindows 
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
		-lm \
	 	-lpthread -L/usr/lib $(LIBEXPAT_STATIC_PATH)/libexpat.a -lcurl \
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
		/sw/lib/libssl.a /sw/lib/libcrypto.a \
		$(LIBEXPAT_STATIC_PATH)/libexpat.a \
		-L/usr/lib -lgetopt -lm -lpthread /sw/lib/libz.a
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
ifeq "$(OS)" "openwrt"
	LDFLAGS+=-lcrypto -lssl -lz
endif

#rules ####################################################
all: $(CDEPFILES:%.c=.%.d) $(LDEPFILES:%.pkg=.%.d) $(BINARY)
	$(H)echo -n

clean:
	$(H)rm -f $(CDEPFILES:%.c=.%.d) $(OBJ)\
		$(LDEPFILES:%.pkg=.%.d) $(LDEPFILES:%.pkg=%.c) \
		$(LDEPFILES:%.pkg=%.h) $(BINARY) \
		lua_updates/*lua lua_updates/*/*lua lua_unofficial/*lua

	
#############################################

$(BINARY): $(OBJ) $(addsuffix .a,$(addprefix ../modules/lib/lib,$(LIBS)))
	$(H)echo -n " linking "
#	$(H)$(RANLIB) ../modules/lib/libgetdate.a ../modules/lib/liblua.a
	$(H)$(RANLIB) $(addsuffix .a,$(addprefix ../modules/lib/lib,$(filter-out mlex_lua,$(LIBSTOLINK))))
ifeq "$(OS)" "Windows"
	$(H)mkdir libfp || true
	$(H)cp $(addsuffix .a,$(addprefix ../modules/lib/lib,$(LIBSTOLINK))) \
		libfp
	$(H)cd libfp; for X in *.a; do ar x $$X; done
	$(H)cd libfp; $(DLLTOOL) -e ../exports.o -l ../libfp.lib *.o
	$(H)$(CC) -o libfp.dll -shared exports.o libfp/*o \
		`echo $(LDFLAGS)|sed 's/$(addprefix -l,$(LIBSTOLINK))//'`
	$(H)$(CC) -o $(BINARY) $(OBJ) -L. \
		-lfp `echo $(LDFLAGS)|sed 's/$(addprefix -l,$(LIBSTOLINK))//'`
else
	$(H)$(CC) -o $(BINARY) $(MACHOARCH) $(OBJ) $(LDFLAGS) 
endif
	$(H)echo "$(BINARY)"
	$(H)echo $(DYNLIBS)
	
.%.d:%.c
	$(H)echo " building dep for $<"
	$(H)$(CC) $(CFLAGS) -MM $< > $@;

%.o:%.c
	$(H)echo -n " compiling $< -> "
	$(H)$(CC) $(CFLAGS) $(MACHOARCH) -c $<
	$(H)echo "$@"

	
.PHONY:all	

