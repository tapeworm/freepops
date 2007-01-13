include $(CONFIG)

SERVICE=freepopsservice.exe

all: $(SERVICE) 

$(SERVICE):
	@$(CC) -Wall -Os -o $(SERVICE) freeservice.c winregistry.c -I.
	@$(STRIP) $(SERVICE)

clean:
	rm $(SERVICE) $(DIALOG)
