include $(CONFIG)

HCFLAGS += -I$(PREFIX)/include -I. -DUSE_POPEN=1 \
	-DUSE_DLOPEN=1 -DUSE_READLINE=1 -DLUA_USERCONFIG=\"saconfig.c\"
HLDFLAGS += -L$(PREFIX)/lib
ifeq "$(OS)" "FreeBSD"
	HLDFLAGS+= -llua-host -llualib-host -lm
else
 ifeq "$(OS)" "OpenBSD"
 	HLDFLAGS+= -llua-host -llualib-host -lm
 else
   ifeq "$(OS)" "Cygwin"
 	HLDFLAGS+= -llua-host -llualib-host -lm
   else
 	HLDFLAGS+= -llua-host -llualib-host -lm -ldl
   endif
 endif
endif

ifeq "$(OS)" "Darwin"
HLDFLAGS+= -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lbase64 \
	-lregularexp -llog -llist \
	-L/sw/lib/ -lexpat -lcurl -lreadline -lhistory #-lcurses #-lncurses
else
HLDFLAGS+= -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -lmlex -lportablesocket -lexpat -lregularexp \
	-lbase64 -lcurl -llog -llist -lreadline -lhistory -lcurses -lncurses
endif

H=@

all: $(PREFIX)/bin/luafull
	$(H)echo -n
	
$(PREFIX)/bin/luafull: luafull
	$(H)cp luafull $(PREFIX)/bin || true
	
luafull:
	$(H)echo -n ' building luafull... '
	$(H)[ -f ../../lib/liblua-host.a ] && \
		( $(RANLIB) ../../lib/liblua-host.a; \
		  $(RANLIB) ../../lib/liblualib-host.a )
	$(H)$(HCC) $(HCFLAGS) -o luafull lua.c $(HLDFLAGS) || true
	$(H)echo "done."

clean:
	$(H)rm -f lib/* bin/* luafull
