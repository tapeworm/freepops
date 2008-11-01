#!/bin/sh

###############################################################################
# Made by Enrico Tassi <gareuselesinge@users.sourceforge.net>
# Distributed under the GPL license
#
# This script should create a jail for freepopsd.
#
#
# 

#configure this################################################################

FPBIN="/usr/bin/freepopsd"
FPFILES="/usr/share/freepops/lua"
FPCONF="/etc/freepops"
CHROOTDIR="/var/lib/freepops/chroot-jail/"
USER="nobody"
GROUP="nogroup"

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
for X in var/log/ var/lib/freepops/lua_updates/ var/run/ etc/ usr/share/freepops/ usr/bin/ usr/lib/ lib/ dev/ home/nobody; do
	mkdir -p $X
done
# set permissions 
chmod g+w var/log/
chmod g+w var/run/
chown $USER.$GROUP var/log/
chown $USER.$GROUP var/run/
# for 64 bit 
ln -s lib lib64
cd usr
ln -s lib lib64
cd ..

# needed libs that are linked at compile time 
for X in `ldd $FPBIN | sed 's/=>/*/' | cut -d '*' -f 2 | cut -d \( -f 1 | tr -d '[:blank:]' | cut -c 2-`; do
	mkdir -p `dirname $X`
	cp /$X $X
done
# libc6
for X in `dpkg -L libc6 | grep "^/lib/.*so.*" | grep -v "^/.*/.*/"`; do
	mkdir -p .`dirname $X`
	cp $X .$X
done

#copy etc conffiles
for X in /etc/resolv.conf /etc/hosts /etc/services; do
	cp $X etc/
done

#create ad hoc files
echo "nobody:x:65534:65534:nobody:/nonexistent:/bin/sh" > etc/passwd
echo "nogroup:x:65534:" > etc/group


#make /dev/null
mknod -m 0666 dev/null c 1 3
#make /dev/random
mknod -m 0444 dev/random c 1 8
#make /dev/urandom
mknod -m 0444 dev/urandom c 1 9

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
