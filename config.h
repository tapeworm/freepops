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
#define VERSION 	"0.0.23"
#define PROGRAMNAME	"FreePOPs"
#define PIDFILE 	"/var/run/freepopsd.pid"
#define POP3PORT  	2000
#define MAXTHREADS 	5

// win32
#if defined(WIN32) && !defined(CYGWIN)
	#define LOGFILE		"log.txt"
	#define BINDADDRESS  	INADDR_LOOPBACK
	#define DEFAULT_USERAGENT \
		"Mozilla/5.0 (; U; Win32; en-US; rv:1.6)"\
		" Gecko/20040322 Firefox/0.8"
	//#define FREEPOPSLUA_USER_UNOFFICIAL "lua_unofficial"
#endif

// beos
#ifdef BEOS
	#define LOGFILE		"/var/log/freepops.log"
	#define BINDADDRESS  	INADDR_LOOPBACK
	#define DEFAULT_USERAGENT \
		"Mozilla/5.0 (X11; U; BeOS; en-US; rv:1.6)"\
		" Gecko/20040322 Firefox/0.8"
	//#define FREEPOPSLUA_USER_UNOFFICIAL "lua_unofficial"
#endif

#ifdef MACOSX
	#define LOGFILE		"stdout"
	#define BINDADDRESS  	INADDR_ANY
	#define DEFAULT_USERAGENT \
		"Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O;"\
		" en-US; rv:1.6) Gecko/20040113"
	//#define FREEPOPSLUA_USER_UNOFFICIAL "lua_unofficial"
#endif
		
// unix
#if (!(defined(WIN32) && !defined(CYGWIN))) && (!defined(BEOS)) && (!defined(MACOSX))
	#define LOGFILE		"stdout"
	#define BINDADDRESS  	INADDR_ANY
	#define DEFAULT_USERAGENT \
		"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.6)"\
		" Gecko/20040322 Firefox/0.8"
	//#define FREEPOPSLUA_USER_UNOFFICIAL "%s/.freepops/lua_unofficial"
	
#endif




