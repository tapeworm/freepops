/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	Implements the pop3 protocol interaction with the client,
 *	delegates actions to engine.c
 * Notes:
 *	
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <sys/types.h>
#include <unistd.h>

#if defined(BEOS)
#  include <bsd_mem.h>
#endif

#include "socketcommon.h"
#include "popserver.h"
#include "popstate.h"
#include "threads.h"

#ifdef HAVE_CONFIG_H
	#include "config.h"
#endif

#include "log.h"
#define LOG_ZONE "POPSERVER"

#define HIDDEN static
#define MIN(a,b) (((a)<(b))?(a):(b))

/***********************************************
 * rfc 1939 strings and limits 
 *
 */

#define GUESSED_MAX_LINE_LEN 1024

#define RFC_1939_MAXLINELEN GUESSED_MAX_LINE_LEN
#define RFC_1939_OK  		"+OK"
#define RFC_1939_ERR 		"-ERR"
#define RFC_1939_QUIT		"QUIT"
#define RFC_1939_STAT		"STAT"
#define RFC_1939_LIST		"LIST"
#define RFC_1939_RETR		"RETR"
#define RFC_1939_DELE		"DELE"
#define RFC_1939_NOOP		"NOOP"
#define RFC_1939_RSET		"RSET"
#define RFC_1939_TOP		"TOP"
#define RFC_1939_UIDL		"UIDL"
#define RFC_1939_USER		"USER"
#define RFC_1939_PASS		"PASS"
#define RFC_1734_AUTH		"AUTH"
#define RFC_2449_CAPA  		"CAPA"
#define RFC_NETSCAPE_XSENDER  	"XSENDER"
#define RFC_DEPRECATED_LAST  	"LAST"

/*** local helper functions ***************************************************/

/************************************************
 * Usefull macros and data structures
 *
 */
#define P(a...) snprintf(ans,RFC_1939_MAXLINELEN,a)

struct triplet_t {void*s;void*f;void*p;};

/***********************************************
 * Case insensitive strcmp
 *
 */ 
HIDDEN int matches_bad_client(char* rfc_command,char* received_string)
{
int rc;
char lowercase_command[strlen(rfc_command)+1];

//try case
for(rc=0;rfc_command[rc] != '\0';rc++)
	lowercase_command[rc] = (char)tolower((int)rfc_command[rc]);
rc = strncmp(lowercase_command,received_string,strlen(rfc_command));
if(rc == 0)
	return 1;

return 0;
}

/***********************************************
 * strcmp with case insensitive fallback
 *
 */ 
HIDDEN int matches(char* rfc_command,char* received_string)
{
int rc;

//DBG("comparing '%s' '%s'\n",rfc_command,received_string);

//try strcmp
rc = strncmp(rfc_command,received_string,strlen(rfc_command));
if(rc == 0)
	return 1;

return matches_bad_client(rfc_command,received_string);
}

/***********************************************
 * extracts the n^th parameter from src and puts 
 * it in dest trucating to maxlen chars
 *
 */ 
HIDDEN int extract_param(int n,char* src,char* dest,int maxlen)
{
char* start;
	
for(;n>0;n--)
	{
	start=index(src,' ');
	if (start == NULL)
		return 1;
	src=start+1;
	}

//now start is the end
start=index(src,' ');
if (start==NULL) start=&src[strlen(src)];

snprintf(dest,maxlen,"%s",src);
dest[MIN(start-src,maxlen-1)]='\0';
return 0;
}

/************************************************
 * The logging function of all traffic on sockets
 *
 */ 
HIDDEN void debug(char* c)
{
unsigned int pid;

if(c == NULL)
	return;

#if !(defined(WIN32) && !defined(CYGWIN))
	pid=getpid();
#else
	pid=GetCurrentThreadId();
#endif

if(matches(SOCK_RECEIVED RFC_1939_PASS,c))
	{
	DBG("[%d] %s%s%s\n",pid,SOCK_RECEIVED,RFC_1939_PASS," *********");
	}
else	{
	if (matches(SOCK_INFO "A previous error occurred",c))
		SAY("[%d] %s\n",pid,c);
	DBG("[%d] %s\n",pid,c);	
	}
}

/*** Pop3 implementation ******************************************************/

/***********************************************
 * Pop3 states
 *
 */ 

enum states_e {
	POPSTATE_AUTH , 
	POPSTATE_TRANS, 
	POPSTATE_ERR, 
	POPSTATE_END ,
	POPSTATE_LAST
};

/***********************************************
 * Pop3 errors
 *
 */ 
char * POPSERVER_ERR_MSG[]={
	"SYNTAX ERROR",
	"NETWORK ERROR",
	"AUTH FAILED",
	"INTERNAL ERROR",
	"NO SUCH MESSAGE",
	"MAILBOX LOCKED",
	"INTERNAL: END OF STREAM",
	"DELAY TIME NOT EXPIRED, RETRY LATER",
	"UNKNOWN ERROR, PLEASE FIX"};

enum states_e POPSERVER_ERR_STA[]={
	POPSTATE_LAST,
	POPSTATE_ERR,
	POPSTATE_ERR,
	POPSTATE_ERR,
	POPSTATE_LAST,
	POPSTATE_ERR,
	POPSTATE_ERR,
	POPSTATE_ERR,
	POPSTATE_ERR};

int POPSERVER_ERR_NUM=POPSERVER_ERR_UNKNOWN;


/***********************************************
 * sends a simple 1-line answer 
 *
 */
HIDDEN enum states_e send_result_simple(struct sock_state_t *s,int rc,
		char* err_comment[],enum states_e err_next[],int numerr,
		char* suc_comment,enum states_e suc_next)
{
char ans[RFC_1939_MAXLINELEN];
	
if(rc != 0)
	{
	P("%s %s",RFC_1939_ERR,err_comment[MIN(rc-1,numerr-1)]);
	sock_send(s,ans);

	SAY("%s\n",err_comment[MIN(rc-1,numerr-1)]);
		
	return err_next[rc-1];
	}
else
	{
	P("%s %s",RFC_1939_OK,suc_comment);
	sock_send(s,ans);

	return suc_next;
	}
}

/***********************************************
 * sends a multi-line answer 
 *
 */
HIDDEN enum states_e send_result_multiline(struct sock_state_t *s,int rc,
		char* err_comment[],enum states_e err_next[],int numerr,
		char* buff,enum states_e suc_next)

{
char ans[RFC_1939_MAXLINELEN];
	
if(rc != 0)
	{
	P("%s %s",RFC_1939_ERR,err_comment[MIN(rc-1,numerr-1)]);
	sock_send(s,ans);

	SAY("%s",err_comment[MIN(rc-1,numerr-1)]);
		
	return err_next[rc-1];
	}
else
	{
	P("%s ANSWER FOLLOW",RFC_1939_OK);
	sock_send(s,ans);
	if(*buff != '\0')
		sock_send(s,buff);
	P(".");
	sock_send(s,ans);

	return suc_next;
	}
}

/*********************************************************
 * marshaller for retr
 */
int marshaller_retr(struct popstate_t*p,struct popserver_functions_t *f,
	struct sock_state_t *s, int msg,int lines)
{
return f->retr(p,msg,s);
}

/*********************************************************
 * marshaller for top
 */
int marshaller_top(struct popstate_t*p,struct popserver_functions_t *f,
	struct sock_state_t *s, int msg,int lines)
{
return f->top(p,msg,lines,s);
}

/*********************************************************
 * sends an answer in a small pieces, all getted trough f 
 * that is called untinl returns != 0
 *
 */
HIDDEN enum states_e send_result_callback(
		struct sock_state_t *s,
		struct popstate_t*p,
		struct popserver_functions_t *f,
		int msg,
		int lines,
		int (*marshaller)
			(struct popstate_t*p,struct popserver_functions_t *f,
			struct sock_state_t *s, int msg,int lines),
		char* err_comment[],
		enum states_e err_next[],
		int numerr,
		enum states_e suc_next)
{
char ans[RFC_1939_MAXLINELEN];
int rc = 0;

P("%s ANSWER FOLLOW",RFC_1939_OK);
sock_send(s,ans);

if(sock_error_occurred(s))
		{
		rc = POPSERVER_ERR_NETWORK;
		return err_next[MIN(rc-1,numerr-1)];
		}

rc = marshaller(p,f,s,msg,lines);

if(rc != POPSERVER_ERR_OK && rc != POPSERVER_ERR_EOF)
		{
		P(".");
		sock_send(s,ans);	
		return err_next[MIN(rc-1,numerr-1)];
		}

P(".");
sock_send(s,ans);

if(sock_error_occurred(s))
		{
		rc = POPSERVER_ERR_NETWORK;
		return err_next[MIN(rc-1,numerr-1)];
		}

return suc_next;
}

int popserver_callback(const char* buffer, void* popserver_data)
{
struct sock_state_t *s = (struct sock_state_t *) popserver_data;

if(buffer != NULL)
		{
		sock_sendraw(s,buffer);
		}

if(sock_error_occurred(s))
		{
		return POPSERVER_ERR_NETWORK;
		}

return POPSERVER_ERR_OK;
}


/***********************************************
 * sends a simple 1-line answer
 * use this for unsupported commands
 *
 */
HIDDEN enum states_e send_unsupported(struct sock_state_t *s,
		char* err_cooment,enum states_e err_next)
{
char *		TMP_ERR_MSG[]={err_cooment};
enum states_e 	TMP_ERR_STA[]={err_next};
int 		TMP_ERR_NUM=1;	
return send_result_simple(s,1,TMP_ERR_MSG,TMP_ERR_STA,TMP_ERR_NUM,"",POPSTATE_ERR);
}

/***********************************************
 * sends a simple 1-line answer
 * use this for wrong syntax 
 *
 */
HIDDEN enum states_e send_wrong_syntax(struct sock_state_t *s,char* ask)
{
char ans[RFC_1939_MAXLINELEN];

P("%s WRONG SYNTAX '%s'",RFC_1939_ERR,ask);
sock_send(s,ans);

SAY("WRONG SYNTAX '%s'",ask);

return POPSTATE_ERR;
}

/***********************************************
 * Pop3 POPSTATE_AUTH state implementation
 *
 * Accepts:
 *  QUIT, USER, PASS, CAPA, AUTH
 *
 * Notes: 
 *  The server accepts a PASS command without a USER before,
 *  this is not specifyed in the rfc, but is boaring to fix this
 */ 

HIDDEN enum states_e pop3_POPSTATE_AUTH(struct sock_state_t *s, 
		struct popserver_functions_t* f,
		struct popstate_t* p)
{
char ask[RFC_1939_MAXLINELEN];
enum states_e next;
int rc=0;

sock_receive_with_timeout(s,ask,RFC_1939_MAXLINELEN,POPSERVER_NOOP_TIMEOUT);
if(sock_error_occurred(s))
	return POPSTATE_AUTH;

if(matches(RFC_1939_QUIT,ask)) /*** QUIT *********************/
	{
	rc=f->quit(p);
	
	next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"BYE BYE",POPSTATE_END);
	}
else if (matches(RFC_1939_PASS,ask)) /*** PASS *********************/
	{
	char param[RFC_1939_MAXLINELEN];
	rc=extract_param(1,ask,param,RFC_1939_MAXLINELEN);
	if(rc != 0)
		{
		next=send_wrong_syntax(s,ask);
		}
	else
		{
		rc=f->pass(p,param);

		next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"ACCESS ALLOWED",POPSTATE_TRANS);
		}
	}
else if (matches(RFC_1939_USER,ask)) /*** USER *********************/
	{
	char param[RFC_1939_MAXLINELEN];
	rc=extract_param(1,ask,param,RFC_1939_MAXLINELEN);
	if(rc != 0)
		{
		next=send_wrong_syntax(s,ask);
		}
	else
		{
		rc=f->user(p,param);
		
		next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"PLEASE ENTER PASSWORD",POPSTATE_AUTH);
		}

	}
else if(matches(RFC_1734_AUTH,ask)) /*** AUTH *********************/
	{
	next=send_unsupported(s,"ONLY PASS IS SUPPORTED",POPSTATE_AUTH);
	}
else if(matches(RFC_2449_CAPA,ask)) /*** CAPA *********************/
	{
	next=send_result_multiline(s,0,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"TOP\r\nUSER\r\nUIDL",POPSTATE_AUTH);
	}
else
	{
	next=send_unsupported(s,
		"WRONG/UKNOWN COMMAND IN AUTHORIZATION STATE",POPSTATE_LAST);	
	}
return next;
}

/***********************************************
 * Pop3 POPSTATE_TRANS state implementation
 *
 * Accepts:
 *  STAT,LIST,UIDL,RETR,TOP,QUIT,NOOP,RSET,DELE,XSPOPSTATE_ENDER,LAST,CAPA
 *
 * Notes: 
 */ 



HIDDEN enum states_e pop3_POPSTATE_TRANS(struct sock_state_t *s, 
		struct popserver_functions_t* f,
		struct popstate_t* p)
{
char ask[RFC_1939_MAXLINELEN];
//char ans[RFC_1939_MAXLINELEN];
enum states_e next=POPSTATE_ERR;
int rc=0;

sock_receive_with_timeout(s,ask,RFC_1939_MAXLINELEN,POPSERVER_NOOP_TIMEOUT);
if(sock_error_occurred(s))
	return POPSTATE_TRANS;

if(matches(RFC_1939_STAT,ask)) /*** STAT *********************/
	{
	int num=0,size=0;
	char ans[RFC_1939_MAXLINELEN];
	
	rc=f->stat(p,&num,&size);

	P("%d %d",num,size);
	next=send_result_simple(s,rc,
		POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
		ans,POPSTATE_TRANS);
	}
else if(matches(RFC_1939_LIST,ask)) /*** LIST *********************/
	{
	char param[RFC_1939_MAXLINELEN];
	char * buffer=NULL;
	
	rc=extract_param(1,ask,param,RFC_1939_MAXLINELEN);
	if(rc == 0)
		{
		//one size
		int num=strtol(param,NULL,10);
		
		rc=f->list(p,num,&buffer);

		next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			buffer,POPSTATE_TRANS);

		free(buffer);
		}
	else
		{
		//all sizes
		rc=f->list_all(p,&buffer);
		
		next=send_result_multiline(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			buffer,POPSTATE_TRANS);
		
		free(buffer);
		}

	}
else if(matches(RFC_1939_UIDL,ask)) /*** UIDL *********************/
	{
	char param[RFC_1939_MAXLINELEN];
	char * buffer=NULL;

	rc=extract_param(1,ask,param,RFC_1939_MAXLINELEN);
	if(rc == 0)
		{
		//one uidl
		int num=strtol(param,NULL,10);

		rc=f->uidl(p,num,&buffer);

		next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			buffer,POPSTATE_TRANS);

		free(buffer);
		}
	else
		{
		//all uidl
		rc=f->uidl_all(p,&buffer);
		

		next=send_result_multiline(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,			buffer,POPSTATE_TRANS);
		
		free(buffer);
		}
	}
else if(matches(RFC_1939_RETR,ask)) /*** RETR *********************/
	{
	char param[RFC_1939_MAXLINELEN];
	
	rc=extract_param(1,ask,param,RFC_1939_MAXLINELEN);
	if(rc != 0)
		{
		next=send_wrong_syntax(s,ask);
		}
	else
		{
		int num;
			
		num=strtol(param,NULL,10);

		next=send_result_callback(s,p,f,num,0,marshaller_retr,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			POPSTATE_TRANS);
		}
	}
else if(matches(RFC_1939_TOP,ask)) /*** TOP *********************/
	{
	char param[RFC_1939_MAXLINELEN];
	char param1[RFC_1939_MAXLINELEN];
	int rc1;
	
	rc=extract_param(1,ask,param,RFC_1939_MAXLINELEN);
	if(rc != 0)
		{
		next=send_wrong_syntax(s,ask);
		}
	rc1=extract_param(2,ask,param1,RFC_1939_MAXLINELEN);
	if(rc1 != 0)
		{
		next=send_wrong_syntax(s,ask);
		}

	if(rc1 == 0 && rc == 0)
		{
		long int num;
		long int lines;
	
		num=strtol(param,NULL,10);
		lines=strtol(param1,NULL,10);

		next=send_result_callback(s,p,f,num,lines,marshaller_top,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			POPSTATE_TRANS);
		
		}
	
	}
else if(matches(RFC_1939_QUIT,ask)) /*** QUIT *********************/
	{
	rc=f->quit_update(p);
	
	next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"BYE BYE, UPDATING",POPSTATE_END);
	}
else if(matches(RFC_1939_NOOP,ask)) /*** NOOP *********************/
	{
	rc = f->noop(p);
	
	next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"I'LL WAIT",POPSTATE_TRANS);
	}
else if(matches(RFC_1939_RSET,ask)) /*** RSET *********************/
	{
	rc = f->rset(p);
	
	next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"MALIBOX RESTORED",POPSTATE_TRANS);
	}
else if(matches(RFC_NETSCAPE_XSENDER,ask)) /*** XSENDER *********************/
	{
	next=send_unsupported(s,
		"XSENDER NOT SUPPORTED",POPSTATE_TRANS);
	}
else if(matches(RFC_DEPRECATED_LAST,ask)) /*** LAST**************************/
	{
	next=send_unsupported(s,
		"LAST NOT SUPPORTED",POPSTATE_TRANS);
	}
else if(matches(RFC_2449_CAPA,ask)) /*** CAPA *********************/
	{
	next=send_result_multiline(s,0,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"TOP\r\nUSER\r\nUIDL",POPSTATE_TRANS);
	}
else if(matches(RFC_1939_DELE,ask)) /*** DELE *********************/
	{
	char param[RFC_1939_MAXLINELEN];
	
	rc=extract_param(1,ask,param,RFC_1939_MAXLINELEN);
	if(rc != 0)
		{
		next=send_wrong_syntax(s,ask);
		}
	else
		{
		int num;
			
		num=strtol(param,NULL,10);
		
		rc=f->dele(p,num);
		
		next=send_result_simple(s,rc,
			POPSERVER_ERR_MSG,POPSERVER_ERR_STA,POPSERVER_ERR_NUM,
			"MESSAGE MARKED FOR DELETION",POPSTATE_TRANS);
		}

	}
else
	{
	next=send_unsupported(s,
		"WRONG/UKNOWN COMMAND IN TRANSACTION STATE",POPSTATE_LAST);
	}
return next;
}

/***********************************************
 * The pop3 server is here
 *
 */ 
HIDDEN void pop3_thread(void *data)
{
char ans[RFC_1939_MAXLINELEN];
enum states_e state=POPSTATE_AUTH,last; 
struct sock_state_t* s = (struct sock_state_t*)((struct triplet_t*)data)->s;
struct popserver_functions_t* f = (struct  popserver_functions_t*) 
	((struct triplet_t*)data)->f;
struct popstate_t* p = (struct  popstate_t* )((struct triplet_t*)data)->p;
int stop=0;

free(data);//malloc called by socketcommon

P("%s %s/%s pop3 server ready",RFC_1939_OK,PROGRAMNAME,VERSION);
sock_send(s,ans);

while(!stop)
	{
	if (sock_error_occurred(s))
		{
		if(state != POPSTATE_END)
			f->quit(p);	
		sock_disconnect(s);
		thread_die(pthread_self());
		break;
		}

	last = state;
	switch(state)
		{
		case POPSTATE_AUTH:
			state = pop3_POPSTATE_AUTH(s,f,p);
		break;
		
		case POPSTATE_TRANS:
			state = pop3_POPSTATE_TRANS(s,f,p);
		break;
		
		case POPSTATE_ERR:
			f->quit(p); // to infom 
			sock_disconnect(s);
			thread_die(pthread_self());
			stop=1;
		break;

		case POPSTATE_END:
			DBG("NORMAL EXIT\n");
			sock_disconnect(s);
			thread_die(pthread_self());
			stop=1;
		break;

		case POPSTATE_LAST:
			ERROR_ABORT("internal");
		break;

		}
	
	if (state == POPSTATE_LAST)
		state = last;
	}

delete_popstate_t(p,f->delete_other);

if(!stop)
	{
	DBG("a network error occurred, this thread will die\n");
	}
}



/*** external function implementation *****************************************/

void popserver_start(struct popserver_functions_t* f,
	struct in_addr address,unsigned short port, int maxthreads,
	int (*set_rights)(uid_t,gid_t),uid_t uid,gid_t gid)
{
struct sock_state_t* s,*new;
struct popstate_t* p;
struct triplet_t *data;
pthread_t *pth;
pthread_attr_t *att;
int rc;

thread_init(maxthreads);

s = sock_bind(address,port,RFC_1939_MAXLINELEN,debug);
if(s == NULL)
	{
	ERROR_ABORT("Unable to bind\n");
	}
if(set_rights != NULL)
	{
	if( set_rights(uid,gid) != 0)
		ERROR_ABORT("Unable to set_rights\n");;
	}

while(1)
	{
	new=sock_listen(s);

	thread_clean(); //clean dead threads
	thread_get_free(&pth,&att); //get a free thread
	
	if(pth == NULL)
		{
		sock_disconnect(new);
		thread_notborn(pth);
		SAY("unable to handle connection, no more threads",s);
		continue;
		}


	p = new_popstate_t();

	//create the data to pass to pop3 thread
	data = malloc(sizeof(struct triplet_t)); //free called by pop3_thread
	MALLOC_CHECK(data);
	
	data->f=f;
	data->p=p;
	data->s=new;

	rc = pthread_create(pth,att,
		(void *(*)(void *))pop3_thread,data);

	if(rc != 0)
		{
		free(data);
		ERROR_ABORT("pthread_create failed\n");
		}

	#ifdef WIN32
	//FIXME
	// richiama il log_rotate a run time
	if((char*)log_get_logfile()!=NULL)
		log_rotate((char*)log_get_logfile());
	#endif
	}
}

