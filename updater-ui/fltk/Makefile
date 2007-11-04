include $(CONFIG)
H=@

ifeq "$(OS)" "Windows"
CFLAGS+=$(FLTKCFLAGS) -I. -I../../modules/include
else
CFLAGS+=$(FLTKCFLAGS) -I. -I../../modules/include -fPIC
endif

LDFLAGS=$(FLTKLDFLAGS) 
%.o:%.cxx
	$(H)echo -n " compiling $< -> "
	$(H)$(CXX) $(CFLAGS) $(MACHOARCH) -c $< -o $@
	$(H)echo "$@"

SO=updater_fltk$(SHAREDEXTENSION)

all: $(SO)
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

clean:
	$(H)echo cleaning updater_fltk
	$(H)rm -f *.o $(SO) .*.d
