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

static struct dictionary_t sessions;

struct data_t {
	char* data;
	int used;
};

void  session_save(const char* key,const char* data, int overwrite)
{
struct data_t* tmp;

tmp = (struct data_t*)dictionary_find(&sessions,key);

if (tmp != NULL )
	{
	if ( overwrite)
		session_remove(key);
	else
		return;
	}
else 	{
	STATS_LOG(cookies,1);
	}
	
tmp = (struct data_t*)malloc(sizeof(struct data_t));

MALLOC_CHECK(tmp);

tmp->used = 0;
tmp->data = strdup(data);

if(dictionary_add(&sessions,key,tmp) != 0) {
	if (overwrite) {
		ERROR_ABORT("internal error: "
				"Unable to save session with overwrite set\n");
	} else {
		ERROR_PRINT("Unable to save session, "
				"try setting overwrite parameter");
	}
}
}

const char* session_load_and_lock(const char* key)
{
struct data_t* tmp = (struct data_t*)dictionary_find(&sessions,key);

if(tmp != NULL)
	{
	if ( tmp->used == 0 )
		{
		tmp->used = 1;
		
		return tmp->data;
		}
	else
		return "\a";
	}

return NULL;
}

void  session_remove(const char* key)
{
struct data_t* tmp = (struct data_t*)dictionary_find(&sessions,key);

if(tmp != NULL)
	{
	free(tmp->data);
	free(tmp);
		
	dictionary_remove(&sessions,key);

	STATS_LOG(cookies,-1);
	}
}

void  session_unlock(const char* key)
{
struct data_t* tmp = (struct data_t*)dictionary_find(&sessions,key);

if(tmp != NULL)
	tmp->used = 0;
}

