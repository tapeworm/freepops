#include "session.h"
#include "dictionary.h"
#include "log.h"
#define LOG_ZONE "SESSION"

static struct dictionary_t sessions;

struct data_t {
	char* data;
	int used;
};

void  session_save(char* key, char* data, int overwrite)
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
	
tmp = (struct data_t*)malloc(sizeof(struct data_t));

MALLOC_CHECK(tmp);

tmp->used = 0;
tmp->data = strdup(data);

if(dictionary_add(&sessions,key,tmp) != 0)
	ERROR_ABORT("Unable to save session\n");
}

char* session_load_and_lock(char* key)
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

void  session_remove(char* key)
{
struct data_t* tmp = (struct data_t*)dictionary_find(&sessions,key);

if(tmp != NULL)
	{
	free(tmp->data);
	free(tmp);
		
	dictionary_remove(&sessions,key);
	}
}

void  session_unlock(char* key)
{
struct data_t* tmp = (struct data_t*)dictionary_find(&sessions,key);

if(tmp != NULL)
	tmp->used = 0;
}

