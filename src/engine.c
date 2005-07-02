/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	Implements the politics
 * Notes:
 *	These functions are called by the pop server thread and are common
 *	to all mail engines
 * Authors:
 *	Nicola Cocchiaro <ncocchiaro@users.sourceforge.net> 
 ******************************************************************************/

#include <stdlib.h>
#include <math.h>
 
#ifdef HAVE_CONFIG_H
#	include "config.h"
#endif

#include "popserver.h"
#include "popstate.h"

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "luay.h"

#include "luabox.h"

#include "freepops.h"

#include "log.h"
#define LOG_ZONE "ENGINE"

/******************************************************************************/

struct popstate_other_t {
lua_State* l;
//FIX maybe we need only this
};

void * assign(void*x)
{
return x;
}

#define CAST(a) ((struct popstate_other_t *)a)

/****** Helper functions for get_data() ********/
void size_printer(char *s_ans, size_t nbytes, int msg, struct mail_msg_t *t)
{
snprintf(s_ans, nbytes+1, "%d %d\r\n", msg, get_mailmessage_size(t));
}

void uidl_printer(char *s_ans, size_t nbytes, int msg, struct mail_msg_t *t)
{
if ( get_mailmessage_uidl(t) != NULL) 
	snprintf(s_ans, nbytes+1, "%d %s\r\n", msg, get_mailmessage_uidl(t));
else snprintf(s_ans, nbytes+1, "%d 0\r\n", msg);
}

size_t size_counter(struct mail_msg_t *t)
{
return B(get_mailmessage_size(t));
}

size_t uidl_counter(struct mail_msg_t *t)
{
if (get_mailmessage_uidl(t) != NULL) 
	return strlen(get_mailmessage_uidl(t));
else return 1;
}

//! gets requested data (sizes or uidls) from all mail messages
void get_data(struct popstate_t *p, char **buffer, size_t counter(struct mail_msg_t *), void printer(char *, size_t, int, struct mail_msg_t *))
{
int ind,n;
size_t nbytes = 0;
char *ans, *s_ans;

ans = (char*)malloc(1);
MALLOC_CHECK(ans);

*ans = '\0';
n = get_popstate_nummesg(p);
for (ind = 0; ind < n; ind++)
	{
	struct mail_msg_t *m = get_popstate_mailmessage(p,ind);
	if (m != NULL && !get_mailmessage_flag(m,MAILMESSAGE_DELETE)) 
		{
		nbytes = B(ind+1) + 
			counter(get_popstate_mailmessage(p,ind)) + 3 + 1;
		s_ans = (char*)malloc(nbytes+1);
		MALLOC_CHECK(s_ans);
		printer(s_ans, nbytes, ind+1, get_popstate_mailmessage(p,ind));
		ans = (char*)realloc(ans, strlen(ans)+nbytes+1);
		MALLOC_CHECK(ans);
		strcat(ans, s_ans);
		free(s_ans);
		}
	}
/* remove trailing \r\n */
if(strlen(ans)>1) // what if the string is empty
	ans[strlen(ans)-2]='\0';
*buffer = strdup(ans);
free(ans);
}

/******************************************************************************
 * starts the VM with the freepops stuff, if username is NULL only
 * freepops.bootstrap is called, else freepops.init(username) and init(p).
 */
#define FREEPOPSLUA_FILE "freepops.lua"

lua_State* bootstrap(const char * username, struct popstate_t* p){
	int rc = POPSERVER_ERR_UNKNOWN;
	lua_State* l;
	l = luabox_genbox(LUABOX_STANDARD|LUABOX_LOG|LUABOX_LUAFILESYSTEM);

	putenv("FREEPOPSLUA_PATH_UNOFFICIAL="FREEPOPSLUA_PATH_UNOFFICIAL);
	putenv("FREEPOPS_VERSION="VERSION);

	//FIXME 
	//putenv("FREEPOPSLUA_USER_UNOFFICIAL="FREEPOPSLUA_USER_UNOFFICIAL);

	//open freepops module
	rc = luaL_loadfile(l,FREEPOPSLUA_PATH FREEPOPSLUA_FILE);
	if (rc != 0)
		{
		DBG("Unable to load " FREEPOPSLUA_PATH FREEPOPSLUA_FILE "\n");
		luay_printstack(l);
		
		//for developing purposes
		luay_emptystack(l);
		rc = luaL_loadfile(l,"src/lua/" FREEPOPSLUA_FILE);
		if (rc != 0)
			{
			DBG("Unable to load src/lua/" FREEPOPSLUA_FILE "\n");
			luay_printstack(l);
			
			//for developing purposes
			luay_emptystack(l);
			rc = luaL_loadfile(l,FREEPOPSLUA_FILE);
			if (rc != 0)
				{
				ERROR_PRINT("Unable to load "
						FREEPOPSLUA_FILE "\n");
				luay_printstack(l);
				ERROR_PRINT("Unable to load " FREEPOPSLUA_FILE 
					". Path was '" 
					FREEPOPSLUA_PATH ":src/lua/:./'\n");
				ERROR_SAY("Working dir is %s\n",getenv("PWD"));
				ERROR_SAY("Can't bootstrap without "
					FREEPOPSLUA_FILE"\n");
				lua_close(l);
				return NULL;
				}
			putenv("FREEPOPSLUA_PATH=./");
			}
		putenv("FREEPOPSLUA_PATH=src/lua/");
	} else	{
		putenv("FREEPOPSLUA_PATH="FREEPOPSLUA_PATH);
	}

	rc = lua_pcall(l, 0, LUA_MULTRET, 0);
	if (rc != 0)
		{
		luay_printstack(l);
		lua_close(l);
		return NULL;
		}

	luay_emptystack(l);

	if (username == NULL) {
		luay_call(l, "s|d", "freepops.bootstrap", username, &rc);
		if(rc != 0){
			ERROR_SAY("Error calling freepops.bootstrap");
			luay_printstack(l);
			lua_close(l);
			return NULL;
		}
		luay_emptystack(l);
		
		// add the missing lua stuff
		luabox_addtobox(l,LUABOX_FREEPOPS ^ 
				(LUABOX_LOG & LUABOX_LUAFILESYSTEM));
		
		luay_emptystack(l);
	} else {
		luay_call(l, "s|d", "freepops.init", username, &rc);
		if(rc != 0){
			ERROR_SAY("Error calling freepops.init('%s')",username);
			luay_printstack(l);
			lua_close(l);
			return NULL;
		}
		luay_emptystack(l);
		
		// add the missing lua stuff
		luabox_addtobox(l,LUABOX_FREEPOPS ^ 
				(LUABOX_LOG & LUABOX_LUAFILESYSTEM));
		
		luay_emptystack(l);
		
		luay_call(l, "p|d", "init", p, &rc);	
		if(rc != 0){
			ERROR_SAY("Error calling init function of lua module");
			luay_printstack(l);
			lua_close(l);
			return NULL;
		}
	}
	return l;
}

/******************************************************************************/



int freepops_user(struct popstate_t*p,char* username)
{
int rc = POPSERVER_ERR_UNKNOWN;

struct popstate_other_t * tmp = malloc(sizeof(struct popstate_other_t));	

MALLOC_CHECK(tmp);
new_popstate_other(p,assign,tmp);

tmp->l = bootstrap(username,p);

if ( tmp->l == NULL)
	{
	ERROR_PRINT("Error bootstrapping\n");
	return POPSERVER_ERR_UNKNOWN;
	}

luay_call(tmp->l,"ps|d","user",p,username,&rc);
return rc;
}

int freepops_pass(struct popstate_t*p,char* password)
{
int rc = POPSERVER_ERR_UNKNOWN;
if(CAST(get_popstate_other(p)) == NULL)
	return POPSERVER_ERR_SYNTAX;

luay_call(CAST(get_popstate_other(p))->l,"ps|d","pass",p,password,&rc);

return rc;
}

int freepops_quit(struct popstate_t*p)
{
int rc = POPSERVER_ERR_OK;

if(CAST(get_popstate_other(p)) != NULL &&
   CAST(get_popstate_other(p))->l != NULL )
	luay_call(CAST(get_popstate_other(p))->l,"p|d","quit",p,&rc);

return rc;
}

int freepops_quit_update(struct popstate_t*p)
{
int rc = POPSERVER_ERR_UNKNOWN;

luay_call(CAST(get_popstate_other(p))->l,"p|d","quit_update",p,&rc);

return rc;
}

int freepops_top(struct popstate_t*p,long int msg,long int lines,void *data)
{
int rc = POPSERVER_ERR_UNKNOWN;
struct mail_msg_t *m = get_popstate_mailmessage(p,msg-1);
if (m != NULL && get_mailmessage_flag(m,MAILMESSAGE_DELETE))
	return POPSERVER_ERR_NOMSG;

luay_call(CAST(get_popstate_other(p))->l,"pddp|d","top",p,msg,lines,data,&rc);

return rc;
}

int freepops_retr(struct popstate_t*p,int msg,void* data)
{
int rc = POPSERVER_ERR_UNKNOWN;
struct mail_msg_t *m = get_popstate_mailmessage(p,msg-1);
if (m != NULL && get_mailmessage_flag(m,MAILMESSAGE_DELETE))
	return POPSERVER_ERR_NOMSG;

luay_call(CAST(get_popstate_other(p))->l,"pdp|d","retr",p,msg,data,&rc);

return rc;
}

int freepops_stat(struct popstate_t*p,int *messages,int* size)
{
int rc = POPSERVER_ERR_UNKNOWN;
*messages = * size = 0;
	
luay_call(CAST(get_popstate_other(p))->l,"p|d","stat",p,&rc);

if(rc == POPSERVER_ERR_OK)
	{
	int n,s;
	n = get_popstate_nummesg(p);
	s = get_popstate_boxsize(p);
	
	*size = s;
	*messages = n ;
	}

return rc;
}

int freepops_uidl(struct popstate_t*p,int msg,char **buffer)
{
int rc = POPSERVER_ERR_UNKNOWN;
struct mail_msg_t *m = get_popstate_mailmessage(p,msg-1);
*buffer = NULL;
if (m != NULL && get_mailmessage_flag(m,MAILMESSAGE_DELETE))
	return POPSERVER_ERR_NOMSG;

luay_call(CAST(get_popstate_other(p))->l,"pd|d","uidl",p,msg,&rc);

if(rc == POPSERVER_ERR_OK)
	{
	int size;
	char* ans;
	const char *uidl;
	struct mail_msg_t*m = NULL;
		
	m=get_popstate_mailmessage(p,msg-1);
	if(m == NULL) {
		*buffer = NULL;
		return POPSERVER_ERR_NOMSG;
	}
	uidl = get_mailmessage_uidl(m);
	size = B(msg) + 1 + strlen(uidl) + 1;
	ans = malloc(size);
	MALLOC_CHECK(ans);
	snprintf(ans, size, "%d %s", msg, uidl);
	*buffer = strdup(ans);
	MALLOC_CHECK(*buffer);
	free(ans);
	}

return rc;
}

int freepops_uidl_all(struct popstate_t*p,char **buffer)
{
int rc = POPSERVER_ERR_UNKNOWN;
*buffer = NULL;

luay_call(CAST(get_popstate_other(p))->l,"p|d","uidl_all",p,&rc);

if(rc == POPSERVER_ERR_OK)
	get_data(p, buffer, uidl_counter, uidl_printer);

return rc;
}

int freepops_list(struct popstate_t*p,int msg,char **buffer)
{
int rc = POPSERVER_ERR_UNKNOWN;
struct mail_msg_t *m = get_popstate_mailmessage(p,msg-1);
if (m != NULL && get_mailmessage_flag(m,MAILMESSAGE_DELETE))
	return POPSERVER_ERR_NOMSG;

luay_call(CAST(get_popstate_other(p))->l,"pd|d","list",p,msg,&rc);

if(rc == POPSERVER_ERR_OK)
	{
	int size;
	char* ans;
	int size_mesg;
	struct mail_msg_t*m = NULL;
		
	m=get_popstate_mailmessage(p,msg-1);
	if(m == NULL) {
		*buffer = NULL;
		return POPSERVER_ERR_NOMSG;
	}
		
	size_mesg = get_mailmessage_size(m);
	size = B(msg) + 1 + B(size_mesg) + 1;
	ans = malloc(size);
	MALLOC_CHECK(ans);
	snprintf(ans, size, "%d %d", msg, size_mesg);
	*buffer = strdup(ans);
	MALLOC_CHECK(*buffer);
	free(ans);
	}

return rc;
}

int freepops_list_all(struct popstate_t*p,char **buffer)
{
int rc = POPSERVER_ERR_UNKNOWN;
*buffer = NULL;

luay_call(CAST(get_popstate_other(p))->l,"p|d","list_all",p,&rc);

if(rc == POPSERVER_ERR_OK)
	get_data(p, buffer, size_counter, size_printer);

return rc;
}

int freepops_rset(struct popstate_t*p)
{
int rc = POPSERVER_ERR_UNKNOWN;

luay_call(CAST(get_popstate_other(p))->l,"p|d","rset",p,&rc);

return rc;
}

int freepops_dele(struct popstate_t*p,int msg)
{
int rc = POPSERVER_ERR_UNKNOWN;

luay_call(CAST(get_popstate_other(p))->l,"pd|d","dele",p,msg,&rc);

return rc;
}

int freepops_noop(struct popstate_t*p)
{
int rc = POPSERVER_ERR_UNKNOWN;

luay_call(CAST(get_popstate_other(p))->l,"p|d","noop",p,&rc);

return rc;
}

void freepops_delete_other(void *x)
{
if(x != NULL && CAST(x)->l != NULL)
	lua_close(CAST(x)->l);
free(x);
}

/******************************************************************************/

struct popserver_functions_t freepops_functions=
	{
	user: freepops_user,
	pass: freepops_pass,
	quit: freepops_quit,
	quit_update:freepops_quit_update,
	top:freepops_top,
	retr:freepops_retr,
	stat:freepops_stat,
	uidl:freepops_uidl,
	uidl_all:freepops_uidl_all,
	list:freepops_list,
	list_all:freepops_list_all,
	rset:freepops_rset,
	dele:freepops_dele,
	noop:freepops_noop,
	delete_other:freepops_delete_other
	};

