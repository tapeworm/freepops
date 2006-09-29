include $(CONFIG)

SERVICE=freepopsservice.exe
DIALOG=freepopsdialog.exe

all: $(DIALOG) #$(SERVICE)

$(SERVICE):
	@$(CC) -Wall -Os -o $(SERVICE) freeservice.c winregistry.c -I.
	@$(STRIP) $(SERVICE)

dialog.cxx dialog.h: dialog.fl
	@fluid -c dialog.fl

$(DIALOG): dialog.cxx dialog.h
	fltk-config --compile dialog.cxx
	i586-mingw32msvc-g++ dialog.cxx -o dialog.exe -mwindows -lfltk -lwsock32 -lgdi 
	#$(STRIP) $(DIALOG)

clean:
	rm $(SERVICE) $(DIALOG)
