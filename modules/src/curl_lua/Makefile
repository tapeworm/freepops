include $(CONFIG)

LIBRARY=lib$(TARGET)$(STATICEXTENSION)

CONSTANTS=curlopt.h curl_netrcopt.h curl_form.h curl_authopt.h 

ifeq "$(OS)" "Windows"
	HEADER=$(INCLUDEPATH)/curl/curl.h
else
	HEADER=$(shell ./find_curl.sh)
	# if this fails hack here #########################################
	# HEADER=your path here
	###################################################################
endif

H=@
CFLAGS+= -Wall -I. -I$(PREFIX)/include
ifeq "$(OS)" "Cygwin"
	CFLAGS+= -I/usr/include
endif
ifneq "$(OS)" "Windows"
	CFLAGS+= $(shell curl-config --cflags 2>/dev/null)
endif
OBJ=curl_lua.o

all: $(LIBRARY)
	$(H)echo -n

$(LIBRARY): $(CONSTANTS) $(OBJ)
	$(H)$(CC) $(CFLAGS) -c curl_lua.c 
	$(H)echo -n " linking "
	$(H)$(AR) -r $(LIBRARY) $(OBJ) 2>/dev/null
	$(H)$(RANLIB) $(LIBRARY)
	$(H)echo "$(LIBRARY)"
	$(H)cp curl_lua.h $(PREFIX)/include
	$(H)cp $(LIBRARY) $(PREFIX)/lib || true

clean:
	$(H)rm -f *.o $(LIBRARY) curlopt.h curl_netrcopt.h \
		curl_authopt.h curl_form.h 
		
%.o:%.c
	$(H)echo -n " compiling $< -> "
	$(H)$(CC) $(CFLAGS) -c $<
	$(H)echo "$@"

curlopt.h: $(HEADER)
	$(H)cat $(HEADER) | grep "^ *CINIT(" | sed "s/CINIT(/{\"OPT_/" | \
		tr -s "  " " " | sed "s/, /\",CURLOPTTYPE_/" | \
		sed "s/, / + /" | sed "s/),/},/" > curlopt.h

curl_netrcopt.h:$(HEADER)
	$(H)cat $(HEADER) | grep "^ *CURL_NETRC_[A-Z]*," | \
		sed 's/^ *CURL_\(NETRC_[A-Z]*\),.*$$/{"\1", (int)CURL_\1},/' \
		> curl_netrcopt.h

curl_authopt.h:$(HEADER)
	$(H)cat $(HEADER) | grep "CURLAUTH_" | \
		sed "s/#define *CURL/{\"/" | sed "s/ *\/\*.*\*\///" | \
		sed "s/ /\",/" | sed "s/$$/},/" > curl_authopt.h

curl_form.h: $(HEADER)
	$(H)cat $(HEADER) | grep "^ *CFINIT" | grep -v "CFINIT(NOTHING)" | \
		sed 's/^ *CFINIT(\([^)]*\)),.*$$/{"FORM_\1",CURLFORM_\1},/' \
		> curl_form.h


