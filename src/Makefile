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
ifeq "$(OS)" "Windows"
CFLAGS+= -DFREEPOPSLUA_PATH=\"lua/\"
else
CFLAGS+= -DFREEPOPSLUA_PATH=\"$(PREFIX)share/freepops/lua/\"
endif

BINARY=freepopsd$(EXEEXTENSION)

LIBS=		stringhack_lua	\
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
                luay            \
                tolua++         \
                lua             \
                lualib          
		
EXCLUDELIBS=	serialize_lua \
		browser_lua \
		support_lua
		
LIBSTOLINK=$(filter-out $(EXCLUDELIBS),$(LIBS))

		
ifeq "$(OS)" "Windows"
	#LIBS+= pthread winsystray regex 
	LDFLAGS= -L ../modules/lib \
		-Wl,-whole-archive -lwinsystray -Wl,-no-whole-archive\
		$(addprefix -l,$(LIBSTOLINK)) \
		-lregex -lm -lcurl_nossl -lmingw32 -lwsock32 -lpthread -lgdi32 -mwindows

else
ifeq "$(OS)" "Darwin"
	LDFLAGS=-L../modules/lib $(addprefix -l,$(LIBSTOLINK)) -ldl -lm -lpthread -lcurl
else
	LDFLAGS=-L ../modules/lib $(addprefix -l,$(LIBSTOLINK)) -ldl -lm -lpthread -rdynamic -lcurl
	
endif
endif	

#rules ####################################################
all: $(CDEPFILES:%.c=.%.d) $(LDEPFILES:%.pkg=.%.d) $(BINARY)

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

	
	

