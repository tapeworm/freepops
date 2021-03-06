#!/bin/sh
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
	osx			to compile on a darwin host (sdk10.4u + custom expat:
				you can export the EXTRALIB_PREFIX variable pointing
				to the installation root of your expat installation)
	osx-static	to compile on a darwin host (old osx versions)
	obsd		to compile on a openbsd host
	fbsd 		to compile on a freebsd host
	solaris 	to compile on a solaris host
	beos		to compile on a beos host
	cygwin		to compile on a cygwin environment
	win		to cross-compile for win on a linux host with 
			mingw32msvc (read BUILD for more info) using openssl
	win-gnutls	to cross-compile for win on a linux host with 
			mingw32msvc using gnutls

Flags (need $PKGCONFIG as provided in Debian):
	-luaexpat       use system lua5.1-expat
	-luacurl        use system lua5.1-curl 
	-luafilesystem  use system lua5.1-filesystem 
	-luasocket  	use system lua5.1-socket 
	-lua            use system lua5.1

Flags (need fltk-config):
	-fltk-ui        build the fltk updater user interface

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
CFLAGS="${CFLAGS:-"-O2 -g3 -Wall -Wextra"} -DHAVE_CONFIG_H -I$PWD"
HCFLAGS=${HCFLAGS:-$CFLAGS}
LDFLAGS=${LDFLAGS:-""}
HLDFLAGS=${HLDFLAGS:-$LDFLAGS}
WINDRES=${WINDRES:-windres}
WINDMC=${WINDMC:-windmc}
DLLTOOL=${DLLTOOL:-dlltool}
MAKE=${MAKE:-make}
WHERE=${WHERE:-/usr/local/}
LOCALEDIR=${LOCALEDIR:-/usr/local/share/locale}
TAR=${TAR:-tar}
PATCH=${PATCH:-patch}
SSL=${SSL:-openssl}
FLTKUI=${FLTKUI:-""}
FLTKCFLAGS=${FLTKCFLAGS:-""}
FLTKLDFLAGS=${FLTKLDFLAGS:-""}
MACHOARCH=${MACHOARCH:-""}
LUAFLAGS=${LUAFLAGS:-""}
OSX_SDK=${OSX_SDK:-""}
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
LOCALEDIR=/usr/share/locale
OS=Linux
LUAFLAGS=" -DLUA_USE_LINUX "
}

set_osx() {
set_default
OS=Darwin
OSX_SDK=/Developer/SDKs/MacOSX10.4u.sdk/
EXTRALIB_PREFIX=${EXTRALIB_PREFIX:-/Users/gares/freepops/}
OSXV=10.4
MACHOARCH=" -arch i386 -arch ppc -isysroot $OSX_SDK -mmacosx-version-min=$OSXV"
CFLAGS="$CFLAGS -I${EXTRALIB_PREFIX}include -DMACOSX"
HCFLAGS="$HCFLAGS -I${EXTRALIB_PREFIX}include -DMACOSX"
LUAFLAGS=" -DLUA_USE_MACOSX "
LDFLAGS="$LDFLAGS -L${EXTRALIB_PREFIX}lib -Wl,-syslibroot,$OSX_SDK -mmacosx-version-min=$OSXV"
EXEEXTENSION=".ppc-i386.$OSXV"
FLTKLDFLAGS="-lfltk -framework Carbon -framework ApplicationServices"
FLTKPOST="${EXTRALIB_PREFIX}bin/fltk-config --post"
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
CC=${firstpref}gcc
CXX=${firstpref}g++
DLLPATH=/usr/i586-mingw32msvc/bin/
INCLUDEPATH=/usr/i586-mingw32msvc/include/
LDFLAGSDL=
CURLNAME=curl
HCC=gcc
LD=${firstpref}ld
HLD=ld
AR=${firstpref}ar
HAR=ar
STRIP=${firstpref}strip
HSTRIP=strip
RANLIB=${firstpref}ranlib
HRANLIB=ranlib
WINDRES=${firstpref}windres
WINDMC=${firstpref}windmc
EXEEXTENSION=.exe
SHAREDEXTENSION=.dll
CFLAGS="$CFLAGS -DWIN32 -mwindows " # " -mms-bitfields"
LDFLAGS="$LDFLAGS -lmsvcrt -lmingw32  -lwsock32 -mwindows " # "-mms-bitfields"
DLLTOOL=${firstpref}dlltool
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
LUASOCKET=luasocket

PKGCONFIG=${PKGCONFIG:-pkg-config}

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
			HCFLAGS="$HCFLAGS `$PKGCONFIG lua5.1-expat --cflags`"
			HLDFLAGS="$HLDFLAGS `$PKGCONFIG lua5.1-expat --libs`"
			CFLAGS="$CFLAGS `$PKGCONFIG lua5.1-expat --cflags`"
			LDFLAGS="$LDFLAGS `$PKGCONFIG lua5.1-expat --libs`"
		;;
		-luacurl)
			LUACURL=
			HCFLAGS="$HCFLAGS `$PKGCONFIG lua5.1-curl --cflags`"
			HLDFLAGS="$HLDFLAGS `$PKGCONFIG lua5.1-curl --libs`"
			CFLAGS="$CFLAGS `$PKGCONFIG lua5.1-curl --cflags`"
			LDFLAGS="$LDFLAGS `$PKGCONFIG lua5.1-curl --libs`"
		;;
		-lua)
			LUALUA=
			HCFLAGS="$HCFLAGS `$PKGCONFIG lua5.1 --cflags`"
			HLDFLAGS="$HLDFLAGS `$PKGCONFIG lua5.1 --libs`"
			CFLAGS="$CFLAGS `$PKGCONFIG lua5.1 --cflags`"
			LDFLAGS="$LDFLAGS `$PKGCONFIG lua5.1 --libs`"
		;;
		-luafilesystem)
			LUAFILESYSTEM=
			HCFLAGS="$HCFLAGS `$PKGCONFIG lua5.1-filesystem --cflags`"
			HLDFLAGS="$HLDFLAGS `$PKGCONFIG lua5.1-filesystem --libs`"
			CFLAGS="$CFLAGS `$PKGCONFIG lua5.1-filesystem --cflags`"
			LDFLAGS="$LDFLAGS `$PKGCONFIG lua5.1-filesystem --libs`"
		;;
		-luasocket)
			LUASOCKET=
			HCFLAGS="$HCFLAGS `$PKGCONFIG lua5.1-socket --cflags`"
			HLDFLAGS="$HLDFLAGS `$PKGCONFIG lua5.1-socket --libs`"
			CFLAGS="$CFLAGS `$PKGCONFIG lua5.1-socket --cflags`"
			LDFLAGS="$LDFLAGS `$PKGCONFIG lua5.1-socket --libs`"
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
WINDMC=$WINDMC
DLLTOOL=$DLLTOOL
DLLPATH=$DLLPATH
INCLUDEPATH=$INCLUDEPATH
LDFLAGSDL=$LDFLAGSDL
CURLNAME=$CURLNAME
OS=$OS
MAKE=$MAKE
WHERE=$WHERE
LOCALEDIR=$LOCALEDIR
TAR=$TAR
PATCH=$PATCH
SSL=$SSL

LUAEXPAT=$LUAEXPAT
LUACURL=$LUACURL
LUALUA=$LUALUA
LUAFILESYSTEM=$LUAFILESYSTEM
LUASOCKET=$LUASOCKET

FLTKUI=$FLTKUI
FLTKCFLAGS=$FLTKCFLAGS
FLTKLDFLAGS=$FLTKLDFLAGS

MACHOARCH=$MACHOARCH
LUAFLAGS=$LUAFLAGS
OSX_SDK=$SDK
FLTKPOST=$FLTKPOST
EXTRALIB_PREFIX=$EXTRALIB_PREFIX

EOT

