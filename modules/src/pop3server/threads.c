/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	some functions to handle a thread pool
 * Notes:
 *	uses static data structures, NOT thread safe (should be??)
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <stdlib.h>

#include "threads.h"
#include "beos_compatibility.h"

#include "log.h"
#define LOG_ZONE "POPSERVER"

#define HIDDEN static

/*****************************************************************************/

HIDDEN int max_threads;

#define UNUSED 		0
#define USED 		1
#define WILL_DIE 	2

/*** local data types *********************************************************/

struct thread_t
	{
	pthread_t *pth;
	pthread_attr_t *att;
	int active;
	};

/*** static variables *********************************************************/

HIDDEN struct thread_t *thread_register;

/*** exported functions *******************************************************/

/********************************
 * Inits all threads data structures
 *
 */ 
void thread_init(int n)
{
int i;

//no free for this since it is done only one time
thread_register=calloc(n,sizeof(struct thread_t));

max_threads = n;

for (i=0;i < max_threads;i++)
	{
	thread_register[i].active=UNUSED;
	thread_register[i].pth=NULL;
	thread_register[i].att=NULL;
	}
}

/******************************
 * t announces that will die
 *
 */ 
void thread_die(pthread_t t)
{
int i;
for (i=0;i < max_threads;i++)
	{
	if ((thread_register[i].pth != NULL) && (pthread_equal(t,*thread_register[i].pth)))
		{
		DBG("thread %d will die\n",i);	
		thread_register[i].active=WILL_DIE;
		break;
		}
	}
}

/******************************
 * clean all will-die threads
 *
 */ 
void thread_clean()
{
int i;
for (i=0;i < max_threads;i++)
	{
	if(thread_register[i].active == WILL_DIE)
		{
		pthread_join(*thread_register[i].pth,NULL);
		pthread_attr_destroy(thread_register[i].att);
		free(thread_register[i].pth);
		free(thread_register[i].att);
		thread_register[i].pth=NULL;
		thread_register[i].att=NULL;
		thread_register[i].active=UNUSED;
		DBG("cleaning thread %d\n",i);
		}
	}
}

/*******************************
 * gets a free handler
 *
 */ 
void thread_get_free(pthread_t** t,pthread_attr_t** a)
{
int i;
*t=NULL;
*a=NULL;
for (i=0;i < max_threads;i++)
	{
	if(thread_register[i].active == UNUSED)
		{
		thread_register[i].pth=malloc(sizeof(pthread_t));
		thread_register[i].att=malloc(sizeof(pthread_attr_t));	
		*t=thread_register[i].pth;
		*a=thread_register[i].att;
		pthread_attr_init(*a);
		thread_register[i].active=USED;

		MALLOC_CHECK(*t);
		MALLOC_CHECK(*a);
		
		break;
		}
	}
}

/******************************************************************
 * if called thread_get_free, but the thread has not been created,
 * the structure can be freed on the fly
 *
 */ 
void thread_notborn(pthread_t *t)
{
int i;
for (i=0;i < max_threads;i++)
	{
	if(t == thread_register[i].pth)
		{
		pthread_attr_destroy(thread_register[i].att);
		free(thread_register[i].pth);
		free(thread_register[i].att);
		thread_register[i].pth=NULL;
		thread_register[i].att=NULL;
		thread_register[i].active=UNUSED;
		DBG("aborting thread %d\n",i);
		break;
		}
	}
}
