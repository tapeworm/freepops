#!/bin/bash

set -e

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

[ -d ../packages/ ] || inform_cvs

OLD=`pwd`
cd /tmp
rm -rf freepops-expat
mkdir freepops-expat
cd freepops-expat
apt-get source --download-only expat
tar -xvzf *orig.tar.gz
mv expat-* expat
cd expat
./configure
make
cd $OLD
make distclean
make -C buildfactory dist-rpm
mv dist-rpm ../packages/freepops-rpm

