#include <stdio.h>
#include <stdlib.h>
#include <FL/fl_ask.H>

int main(int argc, char**argv){

	if (argc < 2){
		fprintf(stderr, "usage: %s message\n",argv[0]);
		return 1;
	}

	fl_message(argv[1]);	

	return EXIT_SUCCESS;
}
