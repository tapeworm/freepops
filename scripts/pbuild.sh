#!/bin/bash

set -e

TODO=$1
if [ -z "$TODO" ]; then TODO="woody sarge sid"; fi

BASE_DIR=../packages/
PBUILD=/usr/sbin/pbuilder

### shit hack ###
function curl_map(){
if [ "$1" = "woody" ]; then
	CURL="-ssl"
elif [ "$1" = "sarge" ]; then
	CURL=3
elif [ "$1" = "sid" ]; then
	CURL=3
fi
}

### build a base for pbuilder ###
function build_base(){

echo -e "Building base for $1"
echo -e "You need a line like this in your /etc/sudoers:"
echo -e "\nusername   ALL = NOPASSWD: /usr/sbin/pbuilder\n"
echo -e "If not stop now and add it."
sleep 4

sudo $PBUILD create \
	--mirror http://ftp.debian.org/debian/ --debootstrap debootstrap \
	--distribution $1 --basetgz $BASE_DIR/base-$1.tgz

curl_map $1	
sudo $PBUILD update \
	--basetgz $BASE_DIR/base-$1.tgz \
	--mirror http://ftp.debian.org/debian/ \
	--distribution $1 --debootstrap debootstrap \
	--override-config \
	--extrapackages "tetex-extra libcurl$CURL-dev libcurl$CURL libexpat1-dev bison flex debhelper libreadline4-dev libreadline4 gs-common libssl-dev"
} 

### error message ###
function inform_cvs(){
echo -e "In order to properly build deb for all debian distros you must"
echo -e "have the pbuilder and sudo packages installed and the packages"
echo -e "CVS module. In the latest you will find a README."
echo -e "Try one of the following\n"
echo -e "cvs -d :ext:$USER@cvs.sf.net:/cvsroot/freepops co packages"
echo -e "cvs -d :pserver:anonymous@cvs.sf.net:/cvsroot/freepops login && \ "
echo -e " cvs -d :pserver:anonymous@cvs.sf.net:/cvsroot/freepops co packages\n"
echo -e "This script should be called only by the packages/ scripts, "
echo -e "not by hand."

exit 1
}

### check if the bases are there and build them if not ###
function check_bases(){
[ -d $BASE_DIR ] || inform_cvs
for X in $TODO; do
	[ -e $BASE_DIR/base-$X.tgz ] || build_base $X
done

}

### create the .dsc ###
function prepare_dsc(){

make realclean || true
rm config || true
./configure.sh linux
make -C buildfactory debian-dsc-$2
cp dist-deb/freepops/* $1
chmod a+r $1/*
}

### call pbuild ###
function build(){

rm -rf $2/$BASE_DIR/freepops-$1
mkdir $2/$BASE_DIR/freepops-$1
sudo $PBUILD update \
	--mirror http://ftp.debian.org/debian/ \
	--distribution $1 --debootstrap debootstrap \
	--override-config \
	--basetgz $2/$BASE_DIR/base-$1.tgz
sudo $PBUILD build \
	--basetgz $2/$BASE_DIR/base-$1.tgz \
	--buildresult $2/$BASE_DIR/freepops-$1 \
	--mirror http://ftp.debian.org/debian/ \
	--distribution $1 --debootstrap debootstrap \
	--override-config \
	--debbuildopts "-us -uc" freepops*.dsc
}

### main ###

(check_bases) \
	2>> /tmp/freepops.pbuild.sh.check_bases.err \
	1>> /tmp/freepops.pbuild.sh.check_bases.out
	
for X in $TODO; do
	D=`pwd`
	TMP=`mktemp -d`
	echo -e "\n *** preparing .dsc ($X) ***\n"
	prepare_dsc $TMP $X
	cd $TMP
	echo -e "\n *** building ($X) ***\n"
	build $X $D
	cd $D
	echo -e "\n *** cleaning ($X) ***\n"
	rm -rf $TMP
done
	
#eof
