/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   liberopops.h
  * \brief  This file contains some general defines
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef LIBEROPOPS_H

#include <stdio.h>

#ifdef HAVE_CONFIG_H
 #include "config.h"
#endif

//! global var for -v option
extern int verbose_output;
//! global var for -c option
extern char *configfile;

//! min of two
#ifndef MIN
#define MIN(a,b) (((a)<(b))?(a):(b))
#endif

//! max of two
#ifndef MAX
#define MAX(a,b)	((a<b)?(b):(a))
#endif

//! len
#define B(n)           floor(MAX(log10(n),0) + 1)

//! tags functions NOT exported by a module
#define HIDDEN static

//! the user configuration dir
#define CONFDIR 	"/.liberopops/"

//! the user config file
#define ALT_LIBERO_CONF CONFDIR "libero.cfg"

//! the share path
#ifdef WIN32
#define LIBEROPOPS_SHARE "./"
#else
#define LIBEROPOPS_SHARE "/usr/share/liberopops/"
#endif

#endif
