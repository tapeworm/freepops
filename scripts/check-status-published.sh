#!/bin/bash

echo The following files differ from the one published:
TODO=`find ../updates/published/ -name \*.lua`
for F in $TODO; do
	bF=`basename $F`
	F1=`find . -name $bF | head -n 1`
	if ! diff $F $F1 >/dev/null; then
		D=`diff -u $F $F1 | grep -v 'Id:.*Exp' | wc -l`
		if [ $D -gt 9 ]; then
			echo ' ' $bF "($D lines)"
		fi
	fi
done
