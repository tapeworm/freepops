#!/bin/sh

#set -x

export PATH=/bin:/usr/bin/:/usr/local/bin/
rm -fr /tmp/fp 
mkdir -p /tmp/fp/toupload/ 
cd /tmp/fp 
while [ ! -d freepops ]; do
	cvs -d:ext:gareuselesinge@cvs.freepops.org:/cvsroot/freepops/ \
		co freepops 
	sleep 30
done
cd freepops 
./configure.sh linux 
make tgz-dist 
cp dist-tgz/*.tar.gz ../toupload/ 
make -C /home/tassi/Projects/freepops/mingw32_freepops/ switch-to-gnutls \
	
make -C buildfactory dist-win-gnutls 
cp dist-win/*.exe ../toupload/ 
make -C /home/tassi/Projects/freepops/mingw32_freepops/ switch-to-openssl \
	
make distclean
make -C buildfactory dist-win-openssl 
cp dist-win/*.exe ../toupload/ 
cd ../toupload 
scp * marcello.cs.unibo.it:public_html/beta/daily/ 
ssh marcello.cs.unibo.it &>/dev/null <<EOT
chmod a+r public_html/beta/daily/*
EOT
date
ls -lh
cd
rm -rf /tmp/fp 

#eot
