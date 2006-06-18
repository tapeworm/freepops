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

CVS_ROOT="-d :username@cvs.sf.net:/cvsroot/freepos"
[ -d ../CVSROOT ] || echo -e "You must do:\n\tcd ..\n\tcvs $CVS_ROOT co CVSROOT"

echo "Please wait... cvs mining is slow..."

grep "^avail|[^,]*|" ../CVSROOT/avail | cut -d "|" -f 2- | sed "s/|/ /" | sed "s/,/ /g" | tr -s "  " " " | awk -f scripts/close_ch.awk -v "day=$DAYS" | scripts/cvschpretty.lua > ChangeLog-CVS

cd ..
echo freepops/src/lua/*.lua > freepops/ChangeLog-PLUGINS
cd freepops

cat ChangeLog-PLUGINS | awk -f scripts/close_ch.awk -v "day=$DAYS" | scripts/cvschpretty.lua > ChangeLog-CVS1

# main()

echo "$NEW_DATE $NEW_VERSION" > ChangeLog-Head
cat ChangeLog-Head ChangeLog-CVS ChangeLog-CVS1 ChangeLog > ChangeLog-Complete
mv ChangeLog-Complete ChangeLog
rm ChangeLog-CVS ChangeLog-CVS1 ChangeLog-Head ChangeLog-PLUGINS


