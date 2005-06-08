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
     ifeq "$(OS)" "BeOS"
        LDFLAGS+= -llua -llualib -ldl
     else
       ifeq "$(OS)" "Windows"
         LDFLAGS+= -llua -llualib -lm $(LDFLAGSDL)
       else
         LDFLAGS+= -llua -llualib -lm -ldl
       endif	
     endif
   endif
 endif
endif

ifeq "$(OS)" "Darwin"
LDFLAGS+= -lcrypto_lua -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua -lluafilesystem \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lbase64 \
	-lregularexp -llog -llist \
	-L/sw/lib/ /sw/lib/libexpat.a /sw/lib/libreadline.a \
	/sw/lib/libncurses.a -lcurl -lcrypto -lhistory
else
ifeq "$(OS)" "Darwin-static"
LDFLAGS+= -lcrypto_lua -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua -lluafilesystem \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lbase64 \
	-lregularexp -llog -llist \
	-L/sw/lib/ /sw/lib/libcrypto.a /sw/lib/libssl.a \
	/sw/lib/libexpat.a /sw/lib/libcurl.a /sw/lib/libreadline.a \
	/sw/lib/libncurses.a -L/usr/lib -lhistory -lz
else
ifeq "$(OS)" "Windows"
LDFLAGS+= -lcrypto_lua -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua -lluafilesystem \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lexpat -lregularexp \
	-lbase64 -l$(CURLNAME) -llog -llist -loscompatibility \
	-lpthread -lregex -lwsock32 -lcrypto
else
ifeq "$(OS)" "BeOS"
LDFLAGS+= -lcrypto_lua -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua -lluafilesystem \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lexpat -lregularexp \
	-lbase64 -lcurl -lcrypto -llog -llist -lreadline -lhistory \
	-lbe -lsocket -lbind -lpthread -lncurses
else
LDFLAGS+= -lcrypto_lua -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua -lluafilesystem \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lexpat -lregularexp \
	-lbase64 -lcurl -lcrypto -llog -llist -lreadline -lhistory \
	-lncurses
endif
endif
endif
endif

	
ifeq "$(OS)" "Windows"
	BINARIZE=echo -en \
		"\\043\\041/bin/sh\nwine $(PREFIX)/bin/luafull.exe \\044\\100">\
		luafull;\
		chmod a+x luafull
	EXTENSION=.exe
	
	INSTALLATION=cp luafull* $(PREFIX)/bin || true;\
	     ln -s $(PREFIX)/lib/libpthread.dll $(PREFIX)/bin/;\
	     ln -s $(DLLPATH)/expat.dll $(PREFIX)/bin/;\
	     ln -s $(DLLPATH)/libcurl-3.dll $(PREFIX)/bin/
else
	BINARIZE=
	EXTENSION=
	INSTALLATION=cp luafull $(PREFIX)/bin || true
endif
H=@

all: $(PREFIX)/bin/luafull
	$(H)echo -n
	
$(PREFIX)/bin/luafull: luafull
	$(H)$(INSTALLATION)
	
luafull:
	$(H)echo -n ' building luafull... '
#	$(H)[ -f ../../lib/liblua-host.a ] && \
#		( $(RANLIB) ../../lib/liblua-host.a; \
#		  $(RANLIB) ../../lib/liblualib-host.a )
	$(H)($(RANLIB) ../../lib/liblua-host.a; \
		$(RANLIB) ../../lib/liblualib-host.a; \
		$(RANLIB) ../../lib/liblua.a; \
		$(RANLIB) ../../lib/libluaexpat.a; \
		$(RANLIB) ../../lib/libgetdate.a; \
	        $(RANLIB) ../../lib/libluafilesystem.a	)
	$(H)$(CC) $(CFLAGS) -o $@$(EXTENSION) lua.c $(LDFLAGS) || true
	$(H)$(BINARIZE)
	$(H)echo "done."

clean:
	$(H)rm -f lib/* bin/* luafull luafull.exe
