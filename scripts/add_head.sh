#!/bin/bash

function usage {
echo "usage: add_head.sh [-t] file headfile"
echo "    -t : test only (do not patch)"
}

function add_head {

TEST_ONLY=0

if [ -z "$1" -o -z "$2" ] ; then
	usage
	exit 1
fi

if [ "$1" = "-t" -a -z "$3" ] ; then
	usage
	exit 1
fi

if [ "$1" = "-t" ] ; then
	TEST_ONLY=1
	FILE="$2"
	HEAD="$3"
	FILENEW="$2--"
else
	FILE="$1"
	HEAD="$2"
	FILENEW="$1--"
fi

TMP=`mktemp`

L=`wc -l $HEAD | cut -f 1 -d " "`

head -n $L $FILE > $TMP

if diff $TMP $HEAD >/dev/null; then
	echo "skipping $FILE"
else
	if [ $TEST_ONLY -eq 0 ] ; then
		mv $FILE $FILENEW
		cat $HEAD $FILENEW > $FILE
		rm $FILENEW
	else
		echo "patching $FILE"
	fi
fi

rm $TMP
}

add_head "$@"
