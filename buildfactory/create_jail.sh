#!/bin/sh

###############################################################################
# Made by Enrico Tassi <gareuselesinge@users.sourceforge.net>
# Distributed under the GPL license
#
# This script should create a jail for liberopopsd.
# 

#configure this################################################################

LPBIN="/usr/bin/liberopopsd"
LPFILES="/usr/share/liberopops/libero.cfg /usr/share/liberopops/browsers.txt"
CHROOTDIR="/var/lib/liberopops/chroot-jail/"
USER="nobody"
GROUP="nogroup"

#options parsing###############################################################

case "$1" in
	create)
		echo -n "Creating chroot-jail for liberopops in $CHROOTDIR ..."
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
mkdir -p usr/share/liberopops/
mkdir -p usr/bin/
mkdir -p usr/lib/
mkdir -p lib/
mkdir -p dev/
mkdir -p home/nobody

#copy libs
cp -a /lib/ld-* lib/
cp -a /lib/libc* lib/
cp -a /lib/libm* lib/
cp -a /lib/libnss_db* lib/
cp -a /lib/libnss_dns* lib/
cp -a /lib/libnss_files* lib/
cp -a /lib/libpthread* lib/
cp -a /lib/libresolv* lib/
cp -a /usr/lib/libdb3* usr/lib/

#copy misc
cp /etc/resolv.conf etc/
cp /etc/hosts etc/
cp /etc/services etc/

#create ad hoc files
echo "nobody:x:65534:65534:nobody:/nonexistent:/bin/sh" > etc/passwd
echo "nogroup:x:65534:" > etc/group

#make /dev/null
mknod -m 0666 dev/null c 1 3

#copy liberopos files
cp $LPBIN usr/bin/
cp $LPFILES usr/share/liberopops/

#create the script#############################################################
cat > $CHROOTDIR/start.sh << EOT
#!/bin/sh

export HOME=/home/$USER/
export USER=$USER
cd $CHROOTDIR
chroot . usr/bin/liberopopsd \$@ -s $USER.$GROUP
EOT

chmod a+rx $CHROOTDIR/start.sh

#thats all folks###############################################################
echo "done."

#eof
