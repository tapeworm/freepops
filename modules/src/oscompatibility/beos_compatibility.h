/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   beos_compatibility.h
  * \brief  some macros for beos missing functions
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef BEOS_COMPATIBILILTY_H
#define BEOS_COMPATIBILILTY_H

#ifdef BEOS
#include <pthread.h>

//! no usleep in beos
#define usleep(a) snooze((a) * 1000L)

//! no SHUT_RDWR in beos
#define SHUT_RDWR SHUTDOWN_BOTH

//! no pthread_equal in beos
#define pthread_equal(a,b) ((a)==(b))

/** @name semaphores pthreads porting to BeOS leaks this!
 *
 */ 
//@{
#define sem_t 			sem_id
#define	sem_wait(a) 		acquire_sem(*(a))
#define	sem_post(a)		release_sem(*(a))
#define	sem_destroy(a)		delete_sem(*(a))
#define	sem_init(a,b,c)		((*(a))=create_sem(c,"sem"))
//@}
  
#ifndef index
char* index(const char * s, int i);
#endif

#endif

#endif
