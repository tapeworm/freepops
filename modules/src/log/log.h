/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   log.h
  * \brief  Implements logging function
  * \author Simone Vellei <simone_vellei@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef _LOG_H_
#define _LOG_H_

#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#ifndef WIN32
	#include <syslog.h>
#endif

/** @name Wrappers 
 * After including log.h you have to define the current zone with 
 * the following statement:<BR><TT>
 * #define LOG_ZONE  "CURRENT ZONE"<BR></TT>
 */ 
//@{
//!Wrapper for logging
#define LOGIT(a,b,c,d,e...) {logit(a,b,c,d,e);}
//! Wrapper for module init, logfile will be freed
#define LOG_INIT(logfile) {log_init(logfile);}
//! Wrapper for module shutdown
#define LOG_END() {log_end();}
//!overrides MALLOC_CHECK
#define MALLOC_CHECK(p) {\
	if(p == NULL) \
		ERROR_ABORT("Unable to malloc\n");\
}
//!overrides ERROR_ABORT
#define ERROR_ABORT(a) {\
	LOGIT(LOG_ZONE,"ABORT",__FILE__,__LINE__,a);\
	abort();\
}
//!overrides ERROR_PRINT
#define ERROR_PRINT(a...) {\
	LOGIT(LOG_ZONE,"ERROR",__FILE__,__LINE__,a);\
}
//! DBG needs -v -v
#define DBG(a...) {\
	if (log_get_verbosity() >= 2) {\
		LOGIT(LOG_ZONE,"DBG",__FILE__,__LINE__,a);\
	}\
}
//! SAY needs -v
#define SAY(a...) {\
	if (log_get_verbosity() >= 1) {\
		LOGIT(LOG_ZONE,NULL,NULL,0,a);\
	}\
}
//@}

//! max logfile size in bytes
#define MAX_LOG_SIZE	3000000 

//! len of the log string		
#define MAX_LOG_STRING	1000

/**
 * \brief log in a pretty way
 * 
 * \param zone will be prepended
 * \param preamble string (if NULL the following 2 params are ignored)
 * \param file "__FILE__"
 * \param line "__LINE__"
 * \param str printf like syntax
 * \return 0 on success
 *
 */ 
int logit(char* zone, char* preamble, char*filename,int line,char *str, ...);

//! initialize the log module, logfile will be freed
int log_init(char* logfile);

//! shut down the module
int log_end(void);

//! get verbosity level
int log_get_verbosity(void);

//! set verbosity level
void log_set_verbosity(int v);

int log_rotate(char *logfile);

char *log_get_logfile(void);

#endif
