/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   config.h
  * \brief  Defines some names used by both the program and the Makefile.
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/

// common
#define VERSION 	"0.2.4"
#define PROGRAMNAME	"FreePOPs"
#define PIDFILE 	"/var/run/freepopsd.pid"
#define POP3PORT  	2000
#define MAXTHREADS 	5

// win32
#if defined(WIN32) && !defined(CYGWIN)
	#define LOGFILE		"log.txt"
	#define BINDADDRESS  	INADDR_LOOPBACK
	#define DEFAULT_USERAGENT \
		"Mozilla/5.0 (; U; Win32; en-US; rv:1.7.8)"\
		" Gecko/20050518 Firefox/1.0.4"
	#define FREEPOPSLUA_PATH_UPDATES "lua_updates/"
	#define FREEPOPSLUA_PATH_UNOFFICIAL "lua_unofficial/"
#endif

// beos
#ifdef BEOS
	#define LOGFILE		"/var/log/freepops.log"
	#define BINDADDRESS  	INADDR_LOOPBACK
	#define DEFAULT_USERAGENT \
		"Mozilla/5.0 (X11; U; BeOS; en-US; rv:1.7.8)"\
		" Gecko/20050518 Firefox/1.0.4"
	#define FREEPOPSLUA_PATH_UPDATES "/var/lib/freepops/lua_updates/"
	#define FREEPOPSLUA_PATH_UNOFFICIAL "/var/lib/freepops/lua_unofficial/"
#endif

#ifdef MACOSX
	#define LOGFILE		"stdout"
	#define BINDADDRESS  	INADDR_ANY
	#define DEFAULT_USERAGENT \
		"Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; "\
		"en-US; rv:1.7.5) Gecko/20041107 Firefox/1.0"
	#define FREEPOPSLUA_PATH_UPDATES "src/lua_updates/"
	#define FREEPOPSLUA_PATH_UNOFFICIAL "src/lua_unofficial/"
#endif
		
// unix
#if (!(defined(WIN32) && !defined(CYGWIN))) && (!defined(BEOS)) && (!defined(MACOSX))
	#define LOGFILE		"stdout"
	#define BINDADDRESS  	INADDR_ANY
	#define DEFAULT_USERAGENT \
		"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8)"\
		" Gecko/20050518 Firefox/1.0.4"
	#define FREEPOPSLUA_PATH_UPDATES "/var/lib/freepops/lua_updates/"
	#define FREEPOPSLUA_PATH_UNOFFICIAL "/var/lib/freepops/lua_unofficial/"
#endif




