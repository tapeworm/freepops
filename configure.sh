#!/bin/bash

usage() {
cat << EOT

usage: ./configure.sh <option>

Available options: 
	help		this screen
	linux		to compile on a linux host and install in /usr/local
	linux-gnutls	to compile on a linux host and install in /usr/local
			using gnutls and not openssl
	linux-slack	to compile on a linux slack box (installs in /usr)
	osx		to compile on a darwin host
	osx-static	to compile on a darwin host with some static libs
	obsd		to compile on a openbsd host
	fbsd 		to compile on a freebsd host
	solaris 	to compile on a solaris host
	beos		to compile on a beos host
	cygwin		to compile on a cygwin environment
	win		to cross-compile for win on a linux host with 
			mingw32msvc (read BUILD for more info) using openssl
	win-gnutls	to cross-compile for win on a linux host with 
			mingw32msvc using gnutls

EOT

}

set_default() {
CC=gcc
LD=ld
AR=ar
STRIP=strip
RANLIB=ranlib
HCC=$CC
HLD=$LD
HAR=$AR
HSTRIP=$STRIP
HRANLIB=$RANLIB
EXEEXTENSION=
STATICEXTENSION=.a
SHAREDEXTENSION=.so
CFLAGS="-O2 -g3 -Wall -DHAVE_CONFIG_H -I$PWD"
HCFLAGS=$CFLAGS
LDFLAGS=""
HLDFLAGS=$LDFLAGS
WINDRES=windres
DLLTOOL=dlltool
MAKE=make
WHERE=/usr/local/
TAR=tar
PATCH=patch
SSL=openssl
}

set_linux() {
set_default
OS=Linux
}

set_linux_gnutls() {
set_default
CFLAGS="$CFLAGS -DCRYPTO_IMPLEMENTATION=1"
HCFLAGS="$HCFLAGS -DCRYPTO_IMPLEMENTATION=1"
SSL=gnutls
OS=Linux
}

set_linux_slack() {
set_default
CFLAGS="-O2 -g3 -march=i486 -Wall -DHAVE_CONFIG_H -I$PWD"
WHERE=/usr/
OS=Linux
}

set_osx() {
set_default
OS=Darwin
CFLAGS="$CFLAGS -I/sw/include -DMACOSX"
HCFLAGS="$HCFLAGS -I/sw/include -DMACOSX"
LDFLAGS="$LDFLAGS -bind_at_load -framework Carbon"
HLDFLAGS="$HLDFLAGS -bind_at_load"
}

set_osx_static() {
set_default
OS=Darwin-static
CFLAGS="$CFLAGS -I/sw/include -DMACOSX"
HCFLAGS="$HCFLAGS -I/sw/include -DMACOSX"
LDFLAGS="$LDFLAGS -bind_at_load -framework Carbon"
HLDFLAGS="$HLDFLAGS -bind_at_load"
}

set_solaris() {
set_default
OS=Solaris
CFLAGS="$CFLAGS -DMACOSX -DFREEBSD -I/usr/local/include"
LDFLAGS="$LDFLAGS -L/usr/local/lib -lnsl -lsocket" 
MAKE="gmake SHELL=/bin/bash"
TAR=gtar
PATCH=gpatch
}

set_fbsd() {
set_default
OS=FreeBSD
CFLAGS="$CFLAGS -DMACOSX -DFREEBSD -I/usr/local/include"
LDFLAGS="$LDFLAGS -L/usr/local/lib" 
MAKE=gmake
}

set_obsd() {
set_default
OS=OpenBSD
CFLAGS="$CFLAGS -DMACOSX"
MAKE=gmake
}

set_beos() {
set_default
OS=BeOS
CFLAGS="$CFLAGS -DBEOS -I/boot/home/config/include/ "
LDFLAGS="$LDFLAGS -L/boot/home/config/lib/"
HCFLAGS="$HCFLAGS -DBEOS -I/boot/home/config/include/ "
HLDFLAGS="$HLDFLAGS -L/boot/home/config/lib/"
WHERE=/boot/home/config/
}

set_cygwin() {
set_default
EXEEXTENSION=.exe
SHAREDEXTENSION=.dll
CFLAGS="$CFLAGS -DWIN32 -D_WIN32 -DCYGWIN -mwindows " # -mno-cygwin -mms-bitfields
HCFLAGS="$CFLAGS -DWIN32 -D_WIN32 -DCYGWIN -mwindows " # -mno-cygwin -mms-bitfields
LDFLAGS="$LDFLAGS -mwindows " # -mno-cygwin -mms-bitfields
HLDFLAGS="$LDFLAGS -mwindows " # -mno-cygwin -mms-bitfields
OS=Cygwin
}

set_win() {
local firstpref
local defpref
set_default
firstpref=/usr/bin/i586-mingw32msvc-
defpref=/usr/local/cross-tools/i386-mingw32msvc/bin/
if test -x ${firstpref}gcc; then
	CC=${firstpref}gcc
	DLLPATH=/usr/i586-mingw32msvc/bin/
	INCLUDEPATH=/usr/i586-mingw32msvc/include/
	LDFLAGSDL=
	CURLNAME=curl
else
	CC=${defpref}gcc
	DLLPATH=/usr/local/cross-tools/i386-mingw32msvc/bin/
	INCLUDEPATH=/usr/local/cross-tools/i386-mingw32msvc/include/
	LDFLAGSDL=-ldl
	CURLNAME=curl
fi
HCC=gcc
if test -x ${firstpref}ld; then
	LD=${firstpref}ld
else
	LD=${defpref}ld
fi
HLD=ld
if test -x ${firstpref}ar; then
	AR=${firstpref}ar
else
	AR=${defpref}ar
fi
HAR=ar
if test -x ${firstpref}strip; then
	STRIP=${firstpref}strip
else
	STRIP=${defpref}strip
fi
HSTRIP=strip
if test -x ${firstpref}ranlib; then
	RANLIB=${firstpref}ranlib
else
	RANLIB=${defpref}ranlib
fi
HRANLIB=ranlib
if test -x ${firstpref}windres; then
	WINDRES=${firstpref}windres
else
	WINDRES=/usr/local/cross-tools/bin/i386-mingw32msvc-windres
fi
EXEEXTENSION=.exe
SHAREDEXTENSION=.dll
CFLAGS="$CFLAGS -DWIN32 -mwindows " # " -mms-bitfields"
LDFLAGS="$LDFLAGS -lmsvcrt -lmingw32  -lwsock32 -mwindows " # "-mms-bitfields"
if test -x ${firstpref}dlltool; then
	DLLTOOL=${firstpref}dlltool
else
	DLLTOOL=${defpref}dlltool
fi
OS=Windows
}

set_win_gnutls() {
set_win
CFLAGS="$CFLAGS -DCRYPTO_IMPLEMENTATION=1"
HCFLAGS="$HCFLAGS -DCRYPTO_IMPLEMENTATION=1"
SSL=gnutls
}

if test -z "$1"; then
	usage
	exit 1
fi

if test "$1" = "help"; then
	usage
	exit 1
fi


if test -e config; then
	echo "Found a config file. Do a 'make realclean' or remove it manually."
	exit 1
fi

case $1 in
	help)
		usage
		exit 1
	;;
	linux)
		set_linux
	;;
	linux-gnutls)
		set_linux_gnutls
	;;
	linux-slack)
		set_linux_slack
	;;
	obsd)
		set_obsd
	;;
	solaris)
		set_solaris
	;;
	fbsd)
		set_fbsd
	;;
	osx)
		set_osx
	;;
	osx-static)
		set_osx_static
	;;
	beos)
		set_beos
	;;
	cygwin)
		set_cygwin
	;;
	win)
		set_win
	;;
	win-gnutls)
		set_win_gnutls
	;;
	*)
		usage
		exit 1
	;;
esac

cat > config << EOT
CC=$CC
LD=$LD
AR=$AR
STRIP=$STRIP
RANLIB=$RANLIB
HCC=$HCC
HLD=$HLD
HAR=$HAR
HSTRIP=$HSTRIP
HRANLIB=$HRANLIB
CFLAGS=$CFLAGS
HCFLAGS=$HCFLAGS
LDFLAGS=$LDFLAGS
HLDFLAGS=$HLDFLAGS
EXEEXTENSION=$EXEEXTENSION
STATICEXTENSION=$STATICEXTENSION
SHAREDEXTENSION=$SHAREDEXTENSION
WINDRES=$WINDRES
DLLTOOL=$DLLTOOL
DLLPATH=$DLLPATH
INCLUDEPATH=$INCLUDEPATH
LDFLAGSDL=$LDFLAGSDL
CURLNAME=$CURLNAME
OS=$OS
MAKE=$MAKE
WHERE=$WHERE
TAR=$TAR
PATCH=$PATCH
SSL=$SSL
EOT

