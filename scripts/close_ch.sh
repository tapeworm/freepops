#!/bin/bash

LAST_LINE=`grep "^[0-9]" ChangeLog | head -n 1`
LAST_VERSION=`echo $LAST_LINE | cut -d " " -f 2`
LAST_DATE=`echo $LAST_LINE | cut -d " " -f 1`

NEW_DATE=`date +%d/%m/%Y`
NEW_VERSON_MAJ=`echo $LAST_VERSION | cut -d "." -f 1`
NEW_VERSON_MIN=`echo $LAST_VERSION | cut -d "." -f 2`
NEW_VERSON_PATCH=`echo $LAST_VERSION | cut -d "." -f 3`
(( NEW_VERSON_PATCH= $NEW_VERSON_PATCH + 1 ))

NEW_VERSION="$NEW_VERSON_MAJ.$NEW_VERSON_MIN.$NEW_VERSON_PATCH"

LAST_DAY=`echo $LAST_DATE| cut -d "/" -f 1`
LAST_MONTH=`echo $LAST_DATE| cut -d "/" -f 2`
LAST_YEAR=`echo $LAST_DATE| cut -d "/" -f 3`

LAST_DAYS=`date -d $LAST_MONTH/$LAST_DAY/$LAST_YEAR +%s`
NEW_DAYS=`date +%s`
((DAYS= $NEW_DAYS - $LAST_DAYS ))
((DAYS= $DAYS / 86400))

echo "[`date`] Please wait... cvs mining is slow... (starting from $DAYS days ago)"

make distclean >/dev/null 2>/dev/null

rm ChangeLog-NEW
ALL=`cvs log -d "> $DAYS days ago" 2>/dev/null | scripts/modified.lua`
ALL_NO=`echo $ALL | wc -w`
i=0
for F in $ALL; do
	echo -en "\rprocessing file $i of $ALL_NO"
	scripts/cvs2changelog.lua $DAYS $F >> ChangeLog-NEW
	((i=$i+1))
done 
echo
cat ChangeLog-NEW | scripts/cvschpretty.lua > ChangeLog-NEW-PRETTY
echo "$NEW_DATE $NEW_VERSION" > ChangeLog-Head
cat ChangeLog-Head ChangeLog-NEW-PRETTY ChangeLog > ChangeLog-Complete
mv ChangeLog-Complete ChangeLog
rm ChangeLog-NEW ChangeLog-NEW-PRETTY ChangeLog-Head

echo "[`date`] Finished"


