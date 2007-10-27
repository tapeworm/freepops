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
	void* data;
	};

struct dictionary_t 
	{
	list_t *head;
	pthread_mutex_t lock;
	};

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
struct dictionary_t *dictionary_create(){
struct dictionary_t * tmp;

tmp = malloc(sizeof(struct dictionary_t));
MALLOC_CHECK(tmp);

tmp->head = NULL;
pthread_mutex_init(&(tmp->lock),NULL);

return tmp;
}


int dictionary_find(struct dictionary_t *d,const char* key,
			void **res, int (*op)(void *))
{
list_t *l;
int rc=0;
void * data = NULL;

pthread_mutex_lock(&(d->lock));
l = list_find(d->head,(void*)key,equal);
if (l != NULL) {
	data = ((struct couple_t*)(l->data))->data;
	if (op != NULL) rc = op(data);
}
pthread_mutex_unlock(&(d->lock));

if (res != NULL) {
	*res = data;
}

return rc;
}

int dictionary_remove(
	struct dictionary_t *d, const char* key,
	int (*op)(void *), void(*freedata)(void*))
{
list_t *l;
int rc = 0;
void * data = NULL;

pthread_mutex_lock(&(d->lock));
l = list_find(d->head,(void*)key,equal);
if(l != NULL) {
	data = ((struct couple_t*)(l->data))->data;
	if (op != NULL) {
		rc = op(data);
	}	
	if (rc == 0){
		if (freedata != NULL) freedata(data);
		delete_couple((struct couple_t*)l->data);
		d->head=list_remove(d->head,l);
	}
} else	{
	rc = 1;
}
pthread_mutex_unlock(&(d->lock));

return rc;
}

int dictionary_add(
	struct dictionary_t *d,const char* key,
	void *data, int (*op)(void *), void(*freedata)(void*))
{
list_t *l;
int rc = 1;
void *olddata = NULL;

pthread_mutex_lock(&(d->lock));	
l = list_find(d->head,(void*)key,equal);
if(l == NULL) {
	d->head = list_add(d->head,new_couple(key,data));
} else {
	olddata = ((struct couple_t*)(l->data))->data;
	if (op != NULL) {
		rc = op(olddata);
	} 
	if (rc == 0 && freedata != NULL) {
		freedata(olddata);
		((struct couple_t*)(l->data))->data = data;
	} else {
		rc = 2;
	}
}
pthread_mutex_unlock(&(d->lock));

return rc;
}

