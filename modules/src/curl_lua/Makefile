include $(CONFIG)

LIBRARY=lib$(TARGET)$(STATICEXTENSION)

CONSTANTS=curlopt.h curl_netrcopt.h curl_form.h curl_authopt.h 

H=@
CFLAGS+= -Wall -I. -I$(PREFIX)/include
OBJ=curl_lua.o

all: $(LIBRARY)

$(LIBRARY): $(CONSTANTS) $(OBJ) 
	$(H)gcc -g3 -Wall -fPIC -c curl_lua.c $(CFLAGS)
	$(H)echo -n " linking "
	$(H)$(AR) -r $(LIBRARY) $(OBJ)
	$(H)$(RANLIB) $(LIBRARY)
	$(H)echo "$(LIBRARY)"
	$(H)cp curl_lua.h $(PREFIX)/include
	$(H)cp $(LIBRARY) $(PREFIX)/lib || true

clean:
	$(H)rm -f *.o $(TARGET) curlopt.h curl_netrcopt.h \
		curl_authopt.h curl_form.h core
		
%.o:%.c
	$(H)echo -n " compiling $< -> "
	$(H)$(CC) $(CFLAGS) -c $<
	$(H)echo "$@"

curlopt.h: /usr/include/curl/curl.h
	$(H)cat /usr/include/curl/curl.h | grep "^ *CINIT(" | \
	   	sed "s/CINIT(/{\"OPT_/" | sed -r "s/, +/\",CURLOPTTYPE_/" | \
		sed "s/, / + /" | sed "s/),/},/" > curlopt.h

curl_netrcopt.h: /usr/include/curl/curl.h
	$(H)cat /usr/include/curl/curl.h | grep "^ *CURL_NETRC_[A-Z]*," | \
		cut -f 1 -d "," |  \
		awk '{print "{\"" $$1 "\", (int)" $$1 "}," }' | \
		sed "s/CURL_//" > curl_netrcopt.h

curl_authopt.h: /usr/include/curl/curl.h
	$(H)cat /usr/include/curl/curl.h | grep "CURLAUTH_" | \
		sed "s/#define *CURL/{\"/" | sed "s/ *\/\*.*\*\///" | \
		sed "s/ /\",/" | sed "s/$$/},/" > curl_authopt.h

curl_form.h:/usr/include/curl/curl.h
	$(H)cat  /usr/include/curl/curl.h | grep "^ *CFINIT" | \
		grep -v "CFINIT(NOTHING)" | sed "s/CFINIT(//" | \
		sed "s/),/ ,/" | \
		awk '{print "{\"FORM_" $$1 "\",CURLFORM_" $$1 "},"}'>curl_form.h


