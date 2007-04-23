#!/bin/bash
# vim:ts=4:

usage() {
cat << EOT

usage: ./configure.sh <option> [flag...]

Available options: 
	help		this screen
	linux		to compile on a linux host and install in /usr/local
	linux-gnutls	to compile on a linux host and install in /usr/local
			using gnutls and not openssl
	linux-slack	to compile on a linux slack box (installs in /usr)
	osx-i386	to compile on a darwin host (Xcode 2.4.1 + custom expat)
	osx-ppc		to compile on a darwin host (Xcode 2.4.1 + custom expat)
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

Flags (need pkg-config as provided in Debian):
	-luaexpat       use system lua5.1-expat
	-luacurl        use system lua5.1-curl 
	-luafilesystem  use system lua5.1-filesystem 
	-lua            use system lua5.1

Flags (need fltk-config):
	-fltk-ui        build the fltk updater user interface

Flags:
	-expat-lib-dir  looks for libexpat.a in this path (osx only), default
	                is \$PWD/../lib/lib/

EOT

}

set_default() {
CC=${CC:-gcc}
CXX=${CXX:-g++}
LD=${LD:-ld}
AR=${AR:-ar}
STRIP=${STRIP:-strip}
RANLIB=${RANLIB:-ranlib}
HCC=${HCC:-$CC}
HLD=${HLD:-$LD}
HAR=${HAR:-$AR}
HSTRIP=${HSTRIP:-$STRIP}
HRANLIB=${HRANLIB:-$RANLIB}
EXEEXTENSION=${EXEEXTENSION:-""}
STATICEXTENSION=${STATICEXTENSION:-.a}
SHAREDEXTENSION=${SHAREDEXTENSION:-.so}
CFLAGS=${CFLAGS:-"-O2 -g3 -Wall -DHAVE_CONFIG_H -I$PWD"}
HCFLAGS=${HCFLAGS:-$CFLAGS}
LDFLAGS=${LDFLAGS:-""}
HLDFLAGS=${HLDFLAGS:-$LDFLAGS}
WINDRES=${WINDRES:-windres}
DLLTOOL=${DLLTOOL:-dlltool}
MAKE=${MAKE:-make}
WHERE=${WHERE:-/usr/local/}
TAR=${TAR:-tar}
PATCH=${PATCH:-patch}
SSL=${SSL:-openssl}
FLTKUI=${FLTKUI:-""}
FLTKCFLAGS=${FLTKCFLAGS:-""}
FLTKLDFLAGS=${FLTKLDFLAGS:-""}
MACHOARCH=${MACHOARCH:-""}
LUAFLAGS=${LUAFLAGS:-""}
LIBEXPAT_STATIC_PATH=${LIBEXPAT_STATIC_PATH:-$PWD/../lib/lib/}
}

set_linux() {
set_default
OS=Linux
LUAFLAGS=" -DLUA_USE_LINUX "
}

set_linux_gnutls() {
set_default
CFLAGS="$CFLAGS -DCRYPTO_IMPLEMENTATION=1"
HCFLAGS="$HCFLAGS -DCRYPTO_IMPLEMENTATION=1"
SSL=gnutls
OS=Linux
LUAFLAGS=" -DLUA_USE_LINUX "
}

set_linux_slack() {
set_default
CFLAGS="-O2 -g3 -march=i486 -Wall -DHAVE_CONFIG_H -I$PWD"
WHERE=/usr/
OS=Linux
LUAFLAGS=" -DLUA_USE_LINUX "
}

set_osx_default() {
set_default
OS=Darwin
CFLAGS="$CFLAGS -I/sw/include -DMACOSX"
HCFLAGS="$HCFLAGS -I/sw/include -DMACOSX"
LUAFLAGS=" -DLUA_USE_MACOSX "
}

set_osx_i386(){
set_osx_default
MACHOARCH=" -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4"
LDFLAGS="$LDFLAGS -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4"
EXEEXTENSION=.i386-10.4
}
set_osx_ppc64(){
set_osx_default
MACHOARCH=" -arch ppc64 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4"
LDFLAGS="$LDFLAGS -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4"
EXEEXTENSION=.ppc64-10.4
}
set_osx_x86_64(){
set_osx_default
MACHOARCH=" -arch x86_64 -isysroot /Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4"
LDFLAGS="$LDFLAGS -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/ -mmacosx-version-min=10.4"
EXEEXTENSION=.x86_64-10.4
}

set_osx_ppc(){
set_osx_default
MACHOARCH=" -arch ppc -isysroot /Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3"
LDFLAGS="$LDFLAGS -Wl,-syslibroot,/Developer/SDKs/MacOSX10.3.9.sdk/ -mmacosx-version-min=10.3"
EXEEXTENSION=.ppc-10.3
}

set_osx_static() {
set_default
OS=Darwin-static
CFLAGS="$CFLAGS -I/sw/include -DMACOSX -DOSXSTC"
HCFLAGS="$HCFLAGS -I/sw/include -DMACOSX -DOSXSTC"
LDFLAGS="$LDFLAGS -L/sw/lib" 
HLDFLAGS="$HLDFLAGS -L/sw/lib"
LUAFLAGS=" -DLUA_USE_MACOSX "
if [ `uname -r` = '8.8.3' ]; then
	MACHOARCH=" -arch i386 -arch ppc -mmacosx-version-min=10.3"
fi
}

set_solaris() {
set_default
OS=Solaris
CFLAGS="$CFLAGS -DMACOSX -DFREEBSD -I/usr/local/include"
LDFLAGS="$LDFLAGS -L/usr/local/lib -lnsl -lsocket" 
MAKE="gmake SHELL=/bin/bash"
TAR=gtar
PATCH=gpatch
LUAFLAGS=" -DLUA_USE_LINUX "
}

set_fbsd() {
set_default
OS=FreeBSD
CFLAGS="$CFLAGS -DMACOSX -DFREEBSD -I/usr/local/include"
LDFLAGS="$LDFLAGS -L/usr/local/lib" 
MAKE=gmake
LUAFLAGS=" -DLUA_USE_LINUX "
}

set_obsd() {
set_default
OS=OpenBSD
CFLAGS="$CFLAGS -DMACOSX"
MAKE=gmake
LUAFLAGS=" -DLUA_USE_LINUX "
}

set_beos() {
set_default
OS=BeOS
CFLAGS="$CFLAGS -DBEOS -I/boot/home/config/include/ "
LDFLAGS="$LDFLAGS -L/boot/home/config/lib/"
HCFLAGS="$HCFLAGS -DBEOS -I/boot/home/config/include/ "
HLDFLAGS="$HLDFLAGS -L/boot/home/config/lib/"
WHERE=/boot/home/config/
LUAFLAGS=" -DLUA_USE_LINUX "
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
LUAFLAGS=" -DLUA_USE_LINUX "
}

set_win() {
local firstpref
local defpref
set_default
firstpref=/usr/bin/i586-mingw32msvc-
defpref=/usr/local/cross-tools/i386-mingw32msvc/bin/
if test -x ${firstpref}gcc; then
	CC=${firstpref}gcc
	CXX=${firstpref}g++
	DLLPATH=/usr/i586-mingw32msvc/bin/
	INCLUDEPATH=/usr/i586-mingw32msvc/include/
	LDFLAGSDL=
	CURLNAME=curl
else
	CC=${defpref}gcc
	CXX=${defpref}g++
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
LUAFLAGS=" -DLUA_WIN"
}

set_win_gnutls() {
set_win
CFLAGS="$CFLAGS -DCRYPTO_IMPLEMENTATION=1"
HCFLAGS="$HCFLAGS -DCRYPTO_IMPLEMENTATION=1"
SSL=gnutls
}

set_openwrt() {
set_default
OS=openwrt
CFLAGS="$CFLAGS -DOPENWRT"
}

###############################################
LUAEXPAT=luaexpat
LUACURL=luacurl
LUALUA=lua
LUAFILESYSTEM=luafilesystem

##############################################
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
	osx-i386)
		set_osx_i386
	;;
	osx-ppc)
		set_osx_ppc
	;;
	osx-x86_64)
		set_osx_x86_64
	;;
	osx-ppc64)
		set_osx_ppc64
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
	openwrt)
		set_openwrt
	;;
	*)
		usage
		exit 1
	;;
esac
shift
while [ ! -z "$1" ]; do
	case $1 in
		-luaexpat)
			LUAEXPAT=
			HCFLAGS="$HCFLAGS `pkg-config lua5.1-expat --cflags`"
			HLDFLAGS="$HLDFLAGS `pkg-config lua5.1-expat --libs`"
			CFLAGS="$HCFLAGS `pkg-config lua5.1-expat --cflags`"
			LDFLAGS="$HLDFLAGS `pkg-config lua5.1-expat --libs`"
		;;
		-luacurl)
			LUACURL=
			HCFLAGS="$HCFLAGS `pkg-config lua5.1-curl --cflags`"
			HLDFLAGS="$HLDFLAGS `pkg-config lua5.1-curl --libs`"
			CFLAGS="$HCFLAGS `pkg-config lua5.1-curl --cflags`"
			LDFLAGS="$HLDFLAGS `pkg-config lua5.1-curl --libs`"
		;;
		-lua)
			LUALUA=
			HCFLAGS="$HCFLAGS `pkg-config lua5.1 --cflags`"
			HLDFLAGS="$HLDFLAGS `pkg-config lua5.1 --libs`"
			CFLAGS="$HCFLAGS `pkg-config lua5.1 --cflags`"
			LDFLAGS="$HLDFLAGS `pkg-config lua5.1 --libs`"
		;;
		-luafilesystem)
			LUAFILESYSTEM=
			HCFLAGS="$HCFLAGS `pkg-config lua5.1-filesystem --cflags`"
			HLDFLAGS="$HLDFLAGS `pkg-config lua5.1-filesystem --libs`"
			CFLAGS="$HCFLAGS `pkg-config lua5.1-filesystem --cflags`"
			LDFLAGS="$HLDFLAGS `pkg-config lua5.1-filesystem --libs`"
		;;
		-fltk-ui)
			FLTKUI=1
			if [ "$OS" != "Windows" ]; then
				FLTKCFLAGS=`fltk-config --cflags`
				FLTKLDFLAGS=`fltk-config --ldflags`
			else
				FLTKCFLAGS=""
				FLTKLDFLAGS=" -lfltk -lintl -lgdi32 -lwsock32 -lole32 -luuid -L ../../src/ -lfp"
			fi
		;;
		-expat-lib-dir)
			shift
			LIBEXPAT_STATIC_PATH="$1"
		;;
		*)
			usage
			exit 1
		;;
	esac
	shift
done


cat > config << EOT
CC=$CC
CXX=$CXX
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

LUAEXPAT=$LUAEXPAT
LUACURL=$LUACURL
LUALUA=$LUALUA
LUAFILESYSTEM=$LUAFILESYSTEM

FLTKUI=$FLTKUI
FLTKCFLAGS=$FLTKCFLAGS
FLTKLDFLAGS=$FLTKLDFLAGS

MACHOARCH=$MACHOARCH
LUAFLAGS=$LUAFLAGS

LIBEXPAT_STATIC_PATH=$LIBEXPAT_STATIC_PATH
EOT

