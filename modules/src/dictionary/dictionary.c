/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	A dictionary data structure
 * Notes:
 *	simple implementation O(n)
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <string.h>
#include <pthread.h>

#include "dictionary.h"
#include "log.h"
#define LOG_ZONE "DICTIONARY"

#define HIDDEN static

/******************************************************************************/
struct couple_t 
	{
	char* key;
	void*data;
	};

HIDDEN pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

/******************************************************************************/
HIDDEN struct couple_t *new_couple(const char* k,void *d)
{
struct couple_t *tmp = malloc(sizeof(struct couple_t));
MALLOC_CHECK(tmp);

tmp->data = d;
tmp->key=strdup(k);
MALLOC_CHECK(tmp->key);

return tmp;
}

HIDDEN void delete_couple(struct couple_t *c)
{
free(c->key);
free(c);
}

HIDDEN int equal(void *key,void *couple)
{
char* k = (char*)key;
struct couple_t* c = (struct couple_t*)couple;
//DBG("comparing \"%s\" \"%s\"\n",k,c->key);
return !strcmp(k,c->key);
}

/******************************************************************************/
void* dictionary_find(struct dictionary_t *d,const char* key)
{
list_t *l;
pthread_mutex_lock(&lock);
l = list_find(d->head,(void*)key,equal);
pthread_mutex_unlock(&lock);
if(l != NULL)
	return ((struct couple_t*)(l->data))->data;

return NULL;
}

int dictionary_remove(struct dictionary_t *d,const char* key)
{
list_t *l;
pthread_mutex_lock(&lock);
l = list_find(d->head,(void*)key,equal);
if(l != NULL)
	{
	delete_couple((struct couple_t*)l->data);
	d->head=list_remove(d->head,l);
	pthread_mutex_unlock(&lock);
	return 0;
	}
else
	{
	pthread_mutex_unlock(&lock);
	return 1;
	}
}

int dictionary_add(struct dictionary_t *d,const char* key,void *data)
{
list_t *l;
pthread_mutex_lock(&lock);	
l = list_find(d->head,(void*)key,equal);
if(l == NULL)
	{
	d->head = list_add(d->head,new_couple(key,data));
	pthread_mutex_unlock(&lock);
	}
else
	{
	pthread_mutex_unlock(&lock);
	return 1;
	}

return 0;
}

