/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   threads.h
  * \brief  Some functions to handle a thread pool
  * uses static data structures, NOT thread safe (should be??)
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/



#ifndef THREADS_H
#define THREADS_H

#include <pthread.h>

//! initialize static thread variables, called in main()
void thread_init(int n);
//! a threads says: "I'll die soon, you can wait for me"
void thread_die(pthread_t t);
//! cleans all dead threads
void thread_clean();
//! gets a brand new thread from the pool
void thread_get_free(pthread_t** t,pthread_attr_t** a);
//! undo thread_get_free
void thread_notborn(pthread_t *t);


#endif
