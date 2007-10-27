/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	session persistency	
 * Notes:
 *	
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include "session.h"
#include "dictionary.h"
#include "stats.h"
#include "log.h"
#define LOG_ZONE "SESSION"

#define HIDDEN static
#define LOCKED 17

HIDDEN struct dictionary_t * sessions;

struct data_t {
	char* data;
	int used;
};

/***********************************************************************/

HIDDEN int check_unused_and_lock(struct data_t *d) {
	if (d->used == 0) {
		d->used = 1;
		return 0;
	}
	else return LOCKED;
}

HIDDEN int unlock(struct data_t *d) {
	d->used = 0;
	return 0;
}

HIDDEN void free_data_t(struct data_t *d) {
	free(d->data);
	free(d);
}

/***********************************************************************/

int  session_save(const char* key,const char* data, int overwrite)
{
struct data_t* tmp;
int rc;
void(*freedata)(void*) = NULL;

tmp = (struct data_t*)malloc(sizeof(struct data_t));
MALLOC_CHECK(tmp);
tmp->used = 0;
tmp->data = NULL;

if (overwrite) {
	freedata = (void(*)(void*))free_data_t;
}

rc = dictionary_add(sessions,key,tmp,NULL,freedata);

if (rc == 0 || rc == 1) {
	tmp->data = strdup(data);
	MALLOC_CHECK(tmp->data);
	if (rc == 1) STATS_LOG(cookies,1);
	rc = 0;
} else {
	free(tmp);
}

return rc;
}

const char* session_load_and_lock(const char* key)
{
struct data_t* tmp;
int rc; 

// gcc warning about type punning is wrong, here I'm sure that even if 
// tmp is is passed as a pointer to void it will be assigned only
// with addresses of data_t structs
rc = dictionary_find(sessions,key,(void**)&tmp,(int(*)(void*))check_unused_and_lock);

if (rc == 0 && tmp != NULL) {
	return tmp->data;
} else if (rc == LOCKED) {
	return "\a";
}

return NULL;
}

void  session_remove(const char* key)
{
int rc = dictionary_remove(sessions, key, NULL, (void(*)(void*))free_data_t);

if (rc == 0) STATS_LOG(cookies,-1);
}

void  session_unlock(const char* key)
{
dictionary_find(sessions, key, NULL, (int(*)(void*))unlock);
}

void session_init(){
sessions = dictionary_create();
}
