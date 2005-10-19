include $(CONFIG)

# TARGET and PREFIX are passed

H=@

#get the files ################################################
HDR=$(shell ls *.h  2> /dev/null)

SRC=$(shell ls *.c *.pkg 2> /dev/null)

OBJ=$(subst .c,.o,$(subst .pkg,.o,$(SRC)))

CDEPFILES=$(shell ls *.c 2> /dev/null)
ifneq "$(CDEPFILES)" "" 
	-include $(CDEPFILES:%.c=.%.d)
endif

LDEPFILES=$(shell ls *.pkg 2> /dev/null)
ifneq "$(LDEPFILES)" "" 
	-include $(LDEPFILES:%.pkg=.%.d)
endif

#flags #######################################################
CFLAGS+= -I. -I../modules/include 

ifneq "$(OS)" "Windows"
	CFLAGS+= $(shell curl-config --cflags)
endif

ifeq "$(OS)" "Windows"
	CFLAGS+= -DFREEPOPSLUA_PATH=\"lua/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"lua_unofficial/\"
else
ifeq "$(OS)" "Darwin"
	CFLAGS+= -DFREEPOPSLUA_PATH=\"src/lua/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"src/lua_unofficial/\"
else
#ifeq "$(OS)" "BeOS"
#	CFLAGS+= -DFREEPOPSLUA_PATH=\"$HOME/config/settings/freepops/lua/\"
#	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"$HOME/config/settings/freepops/lua_unofficial/\"
#
#else
	CFLAGS+= -DFREEPOPSLUA_PATH=\"$(PREFIX)share/freepops/lua/\"
	CFLAGS+= -DFREEPOPSLUA_PATH_UNOFFICIAL=\"$(PREFIX)share/freepops/lua_unofficial/\"
#endif
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
                getdate         \
                curl_lua        \
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
		luaexpat	\
		luafilesystem	\
                luay            \
                lua             \
                lualib          
		
EXCLUDELIBS=	serialize_lua \
		browser_lua \
		support_lua
		
LIBSTOLINK=$(filter-out $(EXCLUDELIBS),$(LIBS))

LDFLAGS=$(FORCE_LINK)
		
ifeq "$(OS)" "Windows"
	#LIBS+= pthread winsystray regex 
	LDFLAGS+= -L ../modules/lib \
		-Wl,-whole-archive -lwinsystray -Wl,-no-whole-archive\
		$(addprefix -l,$(LIBSTOLINK)) \
		-lregex -lm -l$(CURLNAME) -lmingw32 -lwsock32 \
			-lpthread -lexpat -lgdi32 -mwindows -lgcrypt -lgpg-error

else
ifeq "$(OS)" "Darwin"
	LDFLAGS+=-L../modules/lib $(addprefix -l,$(LIBSTOLINK)) \
		-lgetopt -lm \
	 	-lpthread -L/usr/lib -L/sw/lib /sw/lib/libexpat.a -lcurl \
		-lcrypto -ldl -lssl -lcrypto -lz 
else
ifeq "$(OS)" "Darwin-static"
	LDFLAGS+=-L../modules/lib $(addprefix -l,$(LIBSTOLINK)) \
		/usr/local/lib/libdl.a /sw/lib/libcurl.a \
		/sw/lib/libssl.a /sw/lib/libcrypto.a \
		/sw/lib/libexpat.a \
		-L/usr/lib -lgetopt -lm -lpthread -lz
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
		$(LDEPFILES:%.pkg=%.h) $(BINARY)

	
#############################################

$(BINARY): $(OBJ) $(addsuffix .a,$(addprefix ../modules/lib/lib,$(LIBS)))
	$(H)echo -n " linking "
#	$(H)$(RANLIB) ../modules/lib/libgetdate.a ../modules/lib/liblua.a
	$(H)$(RANLIB) $(addsuffix .a,$(addprefix ../modules/lib/lib,$(filter-out mlex_lua,$(LIBSTOLINK))))
	$(H)$(CC) -o $(BINARY) $(OBJ) $(LDFLAGS) 
	$(H)echo "$(BINARY)"
	
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

