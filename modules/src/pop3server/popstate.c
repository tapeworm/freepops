/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	Implement the session cache of the pop3 account
 * Notes:
 *
 * Authors:
 * 	Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
 ******************************************************************************/

#include <stdlib.h>
#include <stdio.h>

#include "popstate.h"
//#include "liberopops.h"
#include "log.h"
#define LOG_ZONE "POPSERVER"

/**
 * \brief This struct represents a mail message.
 *
 */
struct mail_msg_t
	{
	//! flags for the message (to-delete only)
	char flags;
	//! message size in octets
	int size;
	//! message uidl
	char *uidl;
	};

/**
 * \brief This struct is used by the popserver_functions_t functions.
 *
 */ 
struct popstate_t
	{
	// passwd, NULL if not inserted
	char *password;
	// username, NULL if not inserted
	char *username;
	//! number of messages in mailbox, 0 before login
	int num_msgs;
	//! global size of the mailbox
	int size;
	//! pointer to messages list, NULL before login
	struct mail_msg_t **msg_list;
	//! pointer to other fields related to the provider
	void *other;
	//int flags;
	};

/******************************************************************************/
//initialize a mail_msg_t struct
void init_msg(struct mail_msg_t* m);
//free a mailmessage
void delete_mailmessage(struct mail_msg_t* m);
//creates a new mailmessage
struct mail_msg_t* new_mailmessage();

/******************************************************************************/
struct popstate_t *new_popstate_t(void *newp(void))
{
struct popstate_t *tmp;

tmp = malloc(sizeof(struct popstate_t));

if (tmp == NULL)
	ERROR_ABORT("Unable to malloc\n");

//initialization
tmp->username=NULL;
tmp->password=NULL;
tmp->num_msgs=-1;
//tmp->flags=0;
tmp->msg_list=NULL;
tmp->other = NULL;
tmp->size = -1;

return tmp;
}
void new_popstate_other(struct popstate_t *p,void *newp(void*), void* data)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");

if (newp != NULL)
	p->other = newp(data);
else
	p->other = NULL;
}

void* get_popstate_other(struct popstate_t *p)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");

return p->other;
}

//! free memory
void delete_popstate_t(struct popstate_t *p, void deletep(void *))
{
int n;
free(p->username);
free(p->password);

if (p->msg_list)
	{
	for(n=0; n < p->num_msgs; n++)
		delete_mailmessage(p->msg_list[n]);
		
	free(p->msg_list);
	}
if (deletep != NULL)
	deletep(p->other);
free(p);
}

void set_popstate_password(struct popstate_t *p,const char* passwd)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
free(p->password);
p->password = strdup(passwd);
MALLOC_CHECK(p->password);
}

void set_popstate_username(struct popstate_t *p,const char* username)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
free(p->username);
p->username = strdup(username);
MALLOC_CHECK(p->username);
}

void set_popstate_nummesg(struct popstate_t *p,int n)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");

// delete more
for( ; p->num_msgs > n ; p->num_msgs--)
	delete_mailmessage(p->msg_list[p->num_msgs]);

// realloc
p->msg_list = realloc(p->msg_list, sizeof(struct mail_msg_t*) * n);
MALLOC_CHECK(p->msg_list);

if(p->num_msgs == -1)
	p->num_msgs = 0;

// init new
for( ; p->num_msgs < n ; p->num_msgs++)
	p->msg_list[p->num_msgs] = new_mailmessage();
}
/*
void set_popstate_flag(struct popstate_t *p,int flag)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
p->flags |= flag;
}
void unset_popstate_flag(struct popstate_t *p,int flag)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
p->flags &= ~flag;
}
//! get if popstate flag is set
int get_popstate_flag(struct popstate_t *p,int flag)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
return p->flags & flag;
}*/
//! get popstate password, not strdupd
const char* get_popstate_password(struct popstate_t *p)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
return p->password;
}
//! get popstate username, not strdupd
const char* get_popstate_username(struct popstate_t *p)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
return p->username;
}

//! get popstate mailmessage i handler
struct mail_msg_t* get_popstate_mailmessage(struct popstate_t *p,int n)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
if(n >= 0 && n < p->num_msgs)
	return p->msg_list[n];
/*if(n>p->num_msgs)
	{
	set_popstate_nummesg(p,n+1);
	return NULL;
	}*/
return NULL;
}
//! get popstate number of messages
int get_popstate_nummesg(struct popstate_t *p)
{
if(p == NULL)
	ERROR_ABORT("popstate is NULL\n");
return p->num_msgs;
}

/* ========================================================================== */
void init_msg(struct mail_msg_t* m)
{
m->size=0;
m->uidl=NULL;
m->flags=0;
}

//! sets mailmessage size
void set_mailmessage_size(struct mail_msg_t* m,int size)
{
if (m == NULL)
	ERROR_ABORT("mailmessage is NULL\n");
if (size <= 0){
	SAY("setting message size to %d\n",size);
	ERROR_PRINT("invalid size value\n");
}
m->size = size;
}
//! sets mailmessage uidl, string will be duplicated
void set_mailmessage_uidl(struct mail_msg_t* m, const char* uidl)
{
if (m == NULL)
	ERROR_ABORT("mailmessage is NULL\n");
free(m->uidl);
m->uidl = strdup(uidl);
MALLOC_CHECK(m->uidl);
}
//! sets mailmessage flag
void set_mailmessage_flag(struct mail_msg_t* m,int flag)
{
if (m == NULL)
	ERROR_ABORT("mailmessage is NULL\n");
m->flags |= flag;
}
//! sets mailmessage flag
void unset_mailmessage_flag(struct mail_msg_t* m,int flag)
{
if (m == NULL)
	ERROR_ABORT("mailmessage is NULL\n");
m->flags &= ~flag;
}

//! free a mailmessage
void delete_mailmessage(struct mail_msg_t* m)
{
if (m == NULL)
	ERROR_ABORT("mailmessage is NULL\n");

free(m->uidl);
free(m);
}
//! creates a new mailmessage
struct mail_msg_t* new_mailmessage()
{
struct mail_msg_t* m = malloc(sizeof(struct mail_msg_t));
MALLOC_CHECK(m);
init_msg(m);
return m;
}
//! get size
int get_mailmessage_size(struct mail_msg_t* m)
{
if (m == NULL)
	ERROR_ABORT("mailmessage is NULL\n");
return m->size;
}
//! get if flag is set
int get_mailmessage_flag(struct mail_msg_t* m,int flag)
{
if (m == NULL)
	ERROR_ABORT("mailmessage is NULL\n");
return m->flags & flag;
}
//! get the uidl, not strdupd
const char* get_mailmessage_uidl(struct mail_msg_t* m)
{
if (m == NULL)
	ERROR_ABORT("mailmessage is NULL\n");
return m->uidl;
}

int get_popstate_boxsize(struct popstate_t *p)
{
int size = 0, i = 0;

if (p == NULL)
	ERROR_ABORT("popstate is NULL\n");

if( p->size > 0 )
	return p->size;

for(i = 0 ; i < p->num_msgs ; i++)
	size += get_mailmessage_size(get_popstate_mailmessage(p,i));

return size;
}

void set_popstate_boxsize(struct popstate_t *p,int n)
{
if (p == NULL)
	ERROR_ABORT("popstate is NULL\n");

p->size = n;
}

