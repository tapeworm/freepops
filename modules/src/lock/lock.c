/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	mailbox timeout locking
 * Notes:
 *	
 * Authors:
 * 	Simone Vellei <simone_vellei@users.sourceforge.net>
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>

#include "lock.h"
#include "log.h"

#define LOG_ZONE "LOCK"

struct locks {

	char* user;
	int timestamp;
	struct locks *next;

};

static struct locks *lock_table = NULL;
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

// verifica la validità del timestamp
// restituisce 1 se scaduto 0 altrimenti
static int validate_lock(int timestamp,int timeout)
{

	time_t aclock;
	time(&aclock);
	if ((aclock - timestamp) > timeout)
		return 1;
	else
		return 0;

}


static struct locks *get_lock(char *username)
{

	struct locks *tmp;
	
	pthread_mutex_lock(&mutex);
	tmp = lock_table;
	pthread_mutex_unlock(&mutex);
	
	while (tmp != NULL) {

		if (strcmp(username, tmp->user) == 0) 
			return tmp;
		
		tmp = tmp->next;
	}

	return NULL;
}

static int add_lock(char *username,int timeout)
{
	struct locks *tmp;
	time_t aclock;

	time(&aclock);
	tmp = get_lock(username);

	//cerco se è già inserito
	if (tmp != NULL) {
		
		// se non è ancora scaduto il timeout
		// la mailbox è accupata
		if (!validate_lock(tmp->timestamp,timeout))
			return 0;
		else
		// se il timeout è scaduto lo aggiorna 
		// con nuovo valore
		tmp->timestamp = aclock;
	} else {

		// l'utente non è in lista...lo aggiunge
		
		pthread_mutex_lock(&mutex);
		tmp = lock_table;

		lock_table = (struct locks *) malloc(sizeof(struct locks));
		MALLOC_CHECK(lock_table);

		lock_table->user = strdup(username);
		MALLOC_CHECK(lock_table->user);
		lock_table->timestamp = aclock;
		lock_table->next = tmp;
		pthread_mutex_unlock(&mutex);
	}

	return 1;

}


// chiamata per impostare timestamp sulla mailbox
// restituisce 1 se libera 0 se occupata
int mailbox_unlock(char *user, char *domain, int timeout)
{

	char *tmp;
	int len, result;

	// user + domain + '@' + '\0'
	len = strlen(user) + strlen(domain) + 1 + 1;

	tmp = (char *) malloc(len);
	MALLOC_CHECK(tmp);
	
	memset(tmp, '\0', len);

	// tmp contiene il nome utente completo
	snprintf(tmp, len, "%s@%s", user, domain);

	result = add_lock(tmp,timeout);

	free(tmp);

	return result;
}
