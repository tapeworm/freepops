#!/bin/bash

CONTRIB="getdate getopt pthread regex lua luadoc ."

i=0
OLDDIR=`pwd`
for X in modules/src/* src/ ; do
	[ -d $X ]  || continue
	[ `basename $X` != "CVS" ] || continue
	modules[$i]=`basename $X`
	cd $X
	C[$i]=$(expr `find . -name \*.c -exec wc -l \{\} \; | cut -f 1 -d " " | tr -s "\n" "+" | sed s/\+/\ +\ /g` `find . -name \*.h -exec wc -l \{\} \; | cut -f 1 -d " " | tr -s "\n" "+" | sed s/\+/\ +\ /g` 0)
	L[$i]=$(expr `find . -name \*.lua -exec wc -l \{\} \; | cut -f 1 -d " " | tr -s "\n" "+" | sed s/\+/\ +\ /g` `find . -name \*.pkg -exec wc -l \{\} \; | cut -f 1 -d " " | tr -s "\n" "+" | sed s/\+/\ +\ /g` 0)
	cd $OLDDIR
	i=`expr $i + 1`
done
CC=0
LL=0
for (( j = 0 ; j < $i ; j = j + 1 )); do
	N=`echo $CONTRIB | grep "${modules[$j]} " | wc -l` 
	if [ $N -eq 1 ]; then 
		continue;
	fi
	CC=`expr $CC + ${C[$j]}`
	LL=`expr $LL + ${L[$j]}`
done

echo
echo -e "\t+----------------------+-------+-------+"
echo -e "\t|         module       |   C   |  LUA  |"
echo -e "\t+----------------------+-------+-------+"
for (( j = 0 ; j < $i ; j = j + 1 )); do
	printf "\t| %-20s | %5d | %5d |\n" ${modules[$j]} ${C[$j]} ${L[$j]}
done
echo -e "\t+----------------------+-------+-------+"
printf "\t| %-20s | %5d | %5d |\n" "total*" $CC $LL
echo -e "\t+----------------------+-------+-------+"
echo
echo -e "* without contrib modules:\n\t$CONTRIB"
echo


