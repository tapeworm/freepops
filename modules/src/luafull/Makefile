include $(CONFIG)


ifeq "$(OS)" "Windows"
CFLAGS += -I$(PREFIX)/include -I. \
	-DUSE_DLOPEN=1
else
CFLAGS += -I$(PREFIX)/include -I. -DUSE_POPEN=1 \
	-DUSE_DLOPEN=1 -DUSE_READLINE=1 -DLUA_USERCONFIG=\"saconfig.c\"
endif


LDFLAGS += -L$(PREFIX)/lib
ifeq "$(OS)" "FreeBSD"
	LDFLAGS+= -llua -llualib -lm
else
 ifeq "$(OS)" "OpenBSD"
 	LDFLAGS+= -llua -llualib -lm
 else
   ifeq "$(OS)" "Cygwin"
 	LDFLAGS+= -llua -llualib -lm
   else
 	LDFLAGS+= -llua -llualib -lm -ldl
   endif
 endif
endif

ifeq "$(OS)" "Darwin"
LDFLAGS+= -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lbase64 \
	-lregularexp -llog -llist \
	-L/sw/lib/ -lexpat -lcurl -lreadline -lhistory #-lcurses #-lncurses
else
ifeq "$(OS)" "Windows"
LDFLAGS+= -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lexpat -lregularexp \
	-lbase64 -lcurl -llog -llist -loscompatibility \
	-lpthread -lregex -lwsock32
else
LDFLAGS+= -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lexpat -lregularexp \
	-lbase64 -lcurl -llog -llist -lreadline -lhistory -lcurses -lncurses
endif
endif

ifeq "$(OS)" "Windows"
	BINARIZE=echo -en \
		"\\043\\041/bin/sh\nwine $(PREFIX)/bin/luafull.exe \\044\\100">\
		luafull;\
		chmod a+x luafull
	BINARY=luafull.exe
	INST=cp luafull* $(PREFIX)/bin || true;\
	     ln -s $(PREFIX)/lib/libpthread.dll $(PREFIX)/bin/;\
	     ln -s $(PREFIX)/lib/libpthread.dll $(PREFIX)/..;\
	     ln -s /usr/local/cross-tools/i386-mingw32msvc/bin/expat.dll \
	     	$(PREFIX)/bin/;\
 	     ln -s /usr/local/cross-tools/i386-mingw32msvc/bin/expat.dll \
	     	$(PREFIX)/..;\
	     ln -s /usr/local/cross-tools/i386-mingw32msvc/bin/libcurl-3.dll \
	       $(PREFIX)/bin/;\
	     ln -s /usr/local/cross-tools/i386-mingw32msvc/bin/libcurl-3.dll \
	       $(PREFIX)/..
else
	BINARIZE=
	BINARY=luafull
	INST=cp luafull $(PREFIX)/bin || true
endif
H=@

all: $(PREFIX)/bin/luafull
	$(H)echo -n
	
$(PREFIX)/bin/luafull: luafull
	$(H)$(INST)
	
luafull:
	$(H)echo -n ' building luafull... '
#	$(H)[ -f ../../lib/liblua-host.a ] && \
#		( $(RANLIB) ../../lib/liblua-host.a; \
#		  $(RANLIB) ../../lib/liblualib-host.a )
	$(H)($(RANLIB) ../../lib/liblua-host.a; \
		$(RANLIB) ../../lib/liblualib-host.a; \
		$(RANLIB) ../../lib/liblua.a; \
		$(RANLIB) ../../lib/libluaexpat.a; \
		$(RANLIB) ../../lib/libgetdate.a )
	$(H)$(CC) $(CFLAGS) -o $(BINARY) lua.c $(LDFLAGS) || true
	$(H)$(BINARIZE)
	$(H)echo "done."

clean:
	$(H)rm -f lib/* bin/* luafull
