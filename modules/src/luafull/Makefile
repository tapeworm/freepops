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

HLDFLAGS+= -lgetdate_lua -lmlex_lua -lportablesocket_lua \
	-lluaexpat -lregularexp_lua \
	-lbase64_lua -lstringhack_lua -lcurl_lua \
	-lluabind -lgetdate -l mlex -lportablesocket -lexpat -lregularexp \
	-l base64 -lcurl -llog -llist -lreadline -lhistory -lcurses -lncurses

H=@

all: $(PREFIX)/bin/luafull
	
$(PREFIX)/bin/luafull: luafull
	$(H)cp luafull $(PREFIX)/bin
	
luafull:
	$(H)echo -n ' building luafull... '
	$(H)[ -f ../../lib/liblua-host.a] && $(RANLIB) ../../lib/liblua-host.a
	$(H)$(HCC) $(HCFLAGS) -o luafull lua.c $(HLDFLAGS) || true
	$(H)echo "done."

clean:
	$(H)rm -f lib/* bin/* luafull
