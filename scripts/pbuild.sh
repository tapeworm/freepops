#!/bin/bash

TODO=$1
if [ -z "$TODO" ]; then TODO="woody sarge sid"; fi

BASE_DIR=../packages/
PBUILD=/usr/sbin/pbuilder

function curl_map(){
if [ "$1" = "woody" ]; then
	CURL="-ssl"
elif [ "$1" = "sarge" ]; then
	CURL=3
elif [ "$1" = "sid" ]; then
	CURL=3
fi
}

function build_base(){
echo -e "Building base for $1"
echo -e "You need a line like this in your /etc/sudoers:"
echo -e "\nusername   ALL = NOPASSWD: /usr/sbin/pbuilder\n"
echo -e "If not stop now and add it."
sleep 4

sudo $PBUILD create \
	--distribution $1 --basetgz $BASE_DIR/base-$1.tgz

curl_map $1	
sudo $PBUILD update \
	--basetgz $BASE_DIR/base-$1.tgz \
	--extrapackages tetex-extra \
		libcurl$CURL-dev \
		libcurl$CURL \
		libexpat1-dev \
		bison \
		flex \
		debhelper \
		libreadline4-dev \
		libreadline4 \
		gs-common \
		openssl
} 

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


function check_bases(){
[ -d $BASE_DIR ] || inform_cvs
for X in $TODO; do
	[ -e $BASE_DIR/base-$X.tgz ] || build_base $X
done

}

function prepare_dsc(){
dpkg-source -b freepops-*
}

function prepare_tgz(){
make realclean
./configure.sh linux
make tgz-dist
tar -xvzf dist-tgz/* -C $1
}

function build(){
rm -rf $2/$BASE_DIR/freepops-$1
mkdir $2/$BASE_DIR/freepops-$1
sudo $PBUILD update \
	--basetgz $2/$BASE_DIR/base-$1.tgz
sudo $PBUILD build \
	--basetgz $2/$BASE_DIR/base-$1.tgz \
	--buildresult $2/$BASE_DIR/freepops-$1 \
	--debbuildopts "-us -uc" freepops*.dsc
}

check_bases
D=`pwd`
TMP=`mktemp -d`
prepare_tgz $TMP
cd $TMP
prepare_dsc
for X in $TODO; do
	build $X $D			
done
cd $D
rm -rf $TMP
