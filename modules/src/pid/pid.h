/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   pid.h
  * \brief  Implements pid file
  * \author Simone Vellei <simone_vellei@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef _PID_H_
#define _PID_H_

#define PIDERROR 	-1
#define PIDSUCCESS	 0

#define IMROOT          0

#if !(defined(WIN32) && !defined(CYGWIN))
//! creates filestr and write getpid() in it
int create_pid_file(char *filestr);
//! removes the pid file
int remove_pid_file(void);
//! retrieve pid information
int retrieve_pid_file(char*);
#endif

#endif

