include ../../../config 

all: fmessage

H=@

fmessage: fmessage.cpp
	$(H)echo Compiling $< -> $@
	$(H)g++ $(CFLAGS) $(LDFLAGS) $(MACHOARCH) -o $@ $< \
		-L../../../../lib $(FLTKLDFLAGS)
	$(H)$(FLTKPOST) $@ 
	$(H)file $@

clean:
	$(H)rm -f fmessage
