#!/bin/sh

###############################################################################
# Made by Enrico Tassi <gareuselesinge@users.sourceforge.net>
# Distributed under the GPL license
#
# This script should create a jail for freepopsd.
# 

#configure this################################################################

FPBIN="/usr/bin/freepopsd"
FPFILES="/usr/share/freepops/lua"
FPCONF="/etc/freepops"
CHROOTDIR="/var/lib/freepops/chroot-jail/"
USER="nobody"
GROUP="nogroup"
NULL="&>/dev/null"

#options parsing###############################################################

case "$1" in
	create)
		echo -n "Creating chroot-jail for freepops in $CHROOTDIR ..."
	;;
	
	get-dir)
		echo -n "$CHROOTDIR"
		exit 0
	;;
	
	*)
		echo "usage: create_jail.sh (create|get-dir)"
		exit 1
	;;
esac

#create the jail###############################################################

# should we set umask here?

#clean
rm -rf $CHROOTDIR

# create the dir tree
mkdir -p $CHROOTDIR
cd $CHROOTDIR
mkdir -p var/log/
chown $USER.$GROUP var/log/
chmod g+w var/log/
mkdir -p var/run/
chown $USER.$GROUP var/run/
chmod g+w var/run/
mkdir -p etc/
mkdir -p usr/share/freepops/
mkdir -p usr/bin/
mkdir -p usr/lib/
mkdir -p lib/
mkdir -p dev/
mkdir -p home/nobody

#copy libs
cp -a /lib/ld-* lib/ $NULL
cp -a /lib/libc.* lib/ $NULL
cp -a /lib/libc-* lib/ $NULL
cp -a /usr/lib/libcurl*.so* usr/lib/ $NULL
cp -a /usr/lib/libcrypto.so* usr/lib/ $NULL
cp -a /usr/lib/libssl*.so* usr/lib/ $NULL
cp -a /usr/lib/libkrb5.so usr/lib/ $NULL || true
cp -a /usr/lib/libgssapi_krb5.so usr/lib/ $NULL || true
cp -a /usr/lib/libk5crypto.so usr/lib/ $NULL || true
cp -a /lib/libcom_err.so usr/lib/ $NULL || true
cp -a /lib/libdl.so* lib/ $NULL
cp -a /usr/lib/libz.so* usr/lib/ $NULL
cp -a /lib/libm.* lib/ $NULL
cp -a /lib/libm-* lib/ $NULL
cp -a /lib/libdl-* lib/ $NULL
cp -a /lib/libdl.* lib/ $NULL
cp -a /lib/libnss_db* lib/ $NULL
cp -a /lib/libnss_dns* lib/ $NULL
cp -a /lib/libnss_files* lib/ $NULL
cp -a /lib/libpthread* lib/ $NULL
cp -a /lib/libresolv* lib/ $NULL
cp -a /usr/lib/libdb3* usr/lib/ $NULL
cp -a /usr/lib/libexpat* usr/lib/ $NULL
# for sid,sarge
cp -a /usr/lib/libidn* usr/lib/ $NULL || true

#copy misc
cp /etc/resolv.conf etc/
cp /etc/hosts etc/
cp /etc/services etc/

#create ad hoc files
echo "nobody:x:65534:65534:nobody:/nonexistent:/bin/sh" > etc/passwd
echo "nogroup:x:65534:" > etc/group

#make /dev/null
mknod -m 0666 dev/null c 1 3

#copy freepops files
cp $FPBIN usr/bin/
cp -r $FPFILES usr/share/freepops/
cp -r $FPCONF etc/

#create the script#############################################################
cat > $CHROOTDIR/start.sh << EOT
#!/bin/sh

export HOME=/home/$USER/
export USER=$USER
cd $CHROOTDIR
exec -a chroot chroot . usr/bin/freepopsd \$@ -s $USER.$GROUP
EOT

chmod a+rx $CHROOTDIR/start.sh

#thats all folks###############################################################
echo "done."

#eof
