include $(CONFIG)

TGT=freepopsservice.exe

all:
	@$(CC) -Wall -O2 -o $(TGT) *.c -I.
	@$(STRIP) $(TGT)

clean:
	rm $(TGT)
