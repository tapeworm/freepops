#!/bin/sh

usage() {
cat << EOT

Usage: ./configure.sh <option>

Available options: 
	help	this screen
	linux	to compile on a linux host
	osx	to compile on a darwin host
	obsd	to compile on a openbsd host
	fbsd 	to compile on a freebsd host
	beos	to compile on a beos host
	cygwin	to compile on a cygwin environment
	win	to cross-compile for win on a linux host with mingw32msvc

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
}

set_linux() {
set_default
OS=Linux
}

set_osx() {
set_default
OS=Darwin
CFLAGS="$CFLAGS -DMACOSX"
LDFLAGS="$LDFLAGS -framework Carbon"
}

set_obsd() {
set_default
OS=FreeBSD
CFLAGS="$CFLAGS -DMACOSX"
MAKE=gmake
}

set_fbsd() {
set_default
OS=OpenBSD
CFLAGS="$CFLAGS -DMACOSX"
MAKE=gmake
}

set_beos() {
set_default
OS=BeOS
CFLAGS="$CFLAGS -DBEOS"
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
set_default
CC=/usr/local/cross-tools/i386-mingw32msvc/bin/gcc
LD=/usr/local/cross-tools/i386-mingw32msvc/bin/ld
AR=/usr/local/cross-tools/i386-mingw32msvc/bin/ar
STRIP=/usr/local/cross-tools/i386-mingw32msvc/bin/strip
RANLIB=/usr/local/cross-tools/i386-mingw32msvc/bin/ranlib
WINDRES=/usr/local/cross-tools/bin/i386-mingw32msvc-windres
EXEEXTENSION=.exe
SHAREDEXTENSION=.dll
CFLAGS="$CFLAGS -DWIN32 -mwindows " # " -mms-bitfields"
LDFLAGS="$LDFLAGS -lmsvcrt -lmingw32  -lwsock32 -mwindows " # "-mms-bitfields"
DLLTOOL=/usr/local/cross-tools/i386-mingw32msvc/bin/dlltool
OS=Windows
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
	obsd)
		set_obsd
	;;
	fbsd)
		set_fbsd
	;;

	osx)
		set_osx
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
OS=$OS
MAKE=$MAKE
EOT

