include ../../../config 

all: fmessage

fmessage: fmessage.cpp
	@echo Compiling $< -> $@
	@g++ $(CFLAGS) $(LDFLAGS) $(MACHOARCH) -o $@ $< $(FLTKLDFLAGS)
	@$(FLTKPOST) $@ 
	@file $@

clean:
	@rm -f fmessage
