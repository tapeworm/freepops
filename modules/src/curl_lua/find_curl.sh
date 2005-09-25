#!/bin/bash

ERRORMSG="unable_to_find_curl.h_you_should_edit_by_hand_the_curl_lua/Makefile"

PREFIX=`curl-config --prefix`
if [ -z "$PREFIX" ]; then
	PATHS=`locate \*curl.h`
	N=0
	for X in $PATHS; do
		N=`expr $N + 1`
	done
	if [ $N != 1 ]; then
		echo $ERRORMSG
	else
		echo $PATHS
	fi
	
else
	HEADER="$PREFIX/include/curl/curl.h"
	if [ -e $HEADER ]; then
		echo $HEADER
	else
		HEADER="$PREFIX/include/curl.h"
		if [ -e $HEADER ]; then
			echo $HEADER
		else
			echo $ERRORMSG
		fi
	fi

fi
