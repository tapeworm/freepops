include $(CONFIG)
H=@

ifeq "$(OS)" "Windows"
CFLAGS+=$(FLTKCFLAGS) -I. -I../../modules/include
else
CFLAGS+=$(FLTKCFLAGS) -I. -I../../modules/include -fPIC
endif

CFLAGS+=-DLOCALEDIR="\"$(LOCALEDIR)\""

LDFLAGS=$(FLTKLDFLAGS)
%.o:%.cxx
	$(H)echo -n " compiling $< -> "
	$(H)$(CXX) $(CFLAGS) $(MACHOARCH) -c $< -o $@
	$(H)echo "$@"

SO=updater_fltk$(SHAREDEXTENSION)

all: $(SO) lang
	$(H)echo -n

updater.cxx updater.h:updater.fl
	$(H)echo -n " processing $< -> "
	$(H)fluid -c updater.fl
	$(H)echo "$@"

$(SO): updater.o main.o linker.o
	$(H)echo -n " linking "
	$(H)$(CXX) -shared -o $@ $^ $(LDFLAGS)
	$(H)echo "$(SO)"

.%.d:%.cxx updater.h
	$(H)echo " building dep for $<"
	$(H)$(CXX) $(CFLAGS) -MM $< > $@;

ifneq ($(MAKECMDGOALS),clean)
	-include .updater.d .main.d .linker.d
endif

lang:
	$(H)echo "building language files for updater_fltk"
	$(H)$(MAKE) -C po all CONFIG="$(PWD)/config" || true

clean:
	$(H)echo cleaning updater_fltk
	$(H)rm -f *.o $(SO) .*.d
	$(H)$(MAKE) -C po clean CONFIG="$(PWD)/config" || true
