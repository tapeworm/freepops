include $(CONFIG)

#get the files ################################################
HDR=$(shell ls *.h  2> /dev/null)
SRC=$(shell ls *.c *.pkg 2> /dev/null)
OBJ=$(subst .c,.o,$(subst .pkg,.o,$(SRC)))
CDEPFILES=$(shell ls *.c 2> /dev/null)

#flags #######################################################
CFLAGS+= -I. -I$(PREFIX)/include

INTERFACE=$(HDR)
LIBRARY=lib$(TARGET)$(STATICEXTENSION)

# TARGET and PREFIX are passed
all: $(CDEPFILES:%.c=.%.d) $(LIBRARY)

$(LIBRARY): $(OBJ) $(INTERFACE)
	@[  -z "$(OBJ)" ] || echo -n " linking "
	@[  -z "$(OBJ)" ] || $(AR) -r $(LIBRARY) $(OBJ)
	@[  -z "$(OBJ)" ] || $(RANLIB) $(LIBRARY)
	@[  -z "$(OBJ)" ] || echo "$(LIBRARY)"
	cp $(INTERFACE) $(PREFIX)/include || true
	@[ ! -z "$(OBJ)" ] || touch $(LIBRARY)
	@[ -z "$(OBJ)" ] || cp $(LIBRARY) $(PREFIX)/lib || true
		
.%.d:%.c
	@echo " building dep for $<"
	@$(CC) $(CFLAGS) -MM $< > $@;

%.o:%.c
	@echo -n " compiling $< -> "
	@$(CC) $(CFLAGS) -c $<
	@echo "$@"

clean:
	@rm *.o
	
-include $(CDEPFILES:%.c=.%.d)	

