/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	wrap functions for sockets
 * Notes:
 *	based on altsocklib.[ch]
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#ifdef WIN32
  #include <winsock.h>
#else
  #include <sys/types.h>
  #include <sys/socket.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "socketcommon.h"
#include "win32_compatibility.h"

#include "log.h"
#define LOG_ZONE "SOCK"

/************************** output functions ****************************/
void sock_error(char *type,int ernum,struct sock_state_t *s)
{
char tmp[s->maxlinelen];

strncpy(tmp,SOCK_ERROR,s->maxlinelen);
strncat(tmp,type,s->maxlinelen);

// uncomment for shell debug
//sockerror(tmp);

snprintf(tmp,s->maxlinelen,"Error calling \"%s\" (code %d - %s)",
         type,ernum,strerror(errno));

sock_print(SOCK_ERROR,tmp,s);
//exit(1);
s->error_occurred=1;
}

void sock_print(char *prebuffer,char *buffer,struct sock_state_t *s)
{
char tmp[s->maxlinelen];

snprintf(tmp,s->maxlinelen,"%s%s\n",prebuffer,buffer);

s->print(tmp);

}

void sock_received(char *buffer,struct sock_state_t *s)
{
sock_print(SOCK_RECEIVED,buffer,s);
}

void sock_sent(char *buffer,struct sock_state_t *s)
{
//if ( buffer[0] == '.' && buffer[1] == '.' )
//	buffer++; // omits double .
sock_print(SOCK_SENT,buffer,s);
}

void sock_info(char *buffer,struct sock_state_t *s)
{
sock_print(SOCK_INFO,buffer,s);
}

/***************************** SEND /RECIVED checked **********************/

void sock_send(struct sock_state_t *s,char* buffer)
{
int rc;
	
if ( s != NULL && ! s->error_occurred )
	{
	if ( (rc=sendstring(s->socket, buffer)) < 0 ) 
		sock_error("sendstring",rc,s);
	else sock_sent(buffer,s);
	}
else
	{
	char tmp[s->maxlinelen];
	
	strncpy(tmp,"A previous error occurred, skipping : sock_send(\"",
		s->maxlinelen);
	strncat(tmp,buffer,s->maxlinelen);
	strncat(tmp,"\")",s->maxlinelen);
	sock_info(tmp,s);
	}

}
void sock_sendraw(struct sock_state_t *s,char* buffer)
{
int rc;
	
if ( s != NULL && ! s->error_occurred )
	{
	if ( (rc=sendstring_raw(s->socket, buffer)) < 0 ) 
		sock_error("sendstring",rc,s);
	else sock_sent(buffer,s);
	}
else
	{
	char tmp[s->maxlinelen];
	
	strncpy(tmp,"A previous error occurred, skipping : sock_send(\"",
		s->maxlinelen);
	strncat(tmp,buffer,s->maxlinelen);
	strncat(tmp,"\")",s->maxlinelen);
	sock_info(tmp,s);
	}

}

int sock_receive(struct sock_state_t *s,char* buffer,int maxlen)
{
if ( ! s->error_occurred)
	{
	int tmp = recvstring( s->socket, buffer, maxlen , s->prb);
	//int tmp = recvstring_with_timeout(s->socket,buffer,maxlen,s->prb,20);
	
	if ( tmp < 0 )
		sock_error("recvstring",tmp,s);
	else 
		sock_received(buffer,s);
	
	return tmp;
	}
else
	{
	char tmp[s->maxlinelen];
	
	strncpy(tmp,"A previous error occurred, skipping : sock_receive",s->maxlinelen);
	
	sock_info(tmp,s);
	
	return -1;
	}
}

int sock_receive_with_timeout(struct sock_state_t *s,char* buffer,int maxlen, int timeout)
{
if ( ! s->error_occurred)
	{
	int tmp = recvstring_with_timeout( s->socket, buffer, maxlen , s->prb, timeout);
	if ( tmp == -2 )
		sock_error("recvstring_with_timeout timeout",tmp,s);
	else
		if ( tmp == -1 )
			sock_error("recvstring_with_timeout error",tmp,s);
		else	{
		sock_received(buffer,s);
		}
		
	return tmp;
	}
else
	{
	char tmp[s->maxlinelen];
	
	strncpy(tmp,"A previous error occurred, skipping : sock_receive",
		s->maxlinelen);
	
	sock_info(tmp,s);
	
	return -1;
	}
}

static void get_info(struct sock_state_t* tmp)
{
unsigned char info[6];

// get server infos
if ( sockinfo(tmp->socket, info)== -1 ) sock_error("sockinfo",-1,tmp);
snprintf( tmp->ipaddress, strlen("255.255.255.255") + 1, 
		"%d.%d.%d.%d" , info[0], info[1], info[2], info[3] );
tmp->realport =  info[4] * 256 + info[5] ;
}



/*********************** connect *********************************************/



struct sock_state_t * sock_connect(char *hostname,
	unsigned long port,int maxlinelen,void (*print)(char *))
{
struct sock_state_t *tmp;
#ifndef WIN32
struct in_addr anyaddress = { INADDR_ANY };
#else
struct in_addr anyaddress = {{{ INADDR_ANY }}};
#endif
char infostring[]="Ip address xxx.xxx.xxx.xxx real port xxxxx";

tmp = (struct sock_state_t *) malloc(sizeof(struct sock_state_t));
if(tmp == NULL)
	return NULL;
	
tmp->maxlinelen = maxlinelen;
tmp->hostname  = strdup(hostname);
tmp->ipaddress = strdup("255.255.255.255");
tmp->welcomestring = (char *) calloc( maxlinelen ,sizeof(char));
tmp->prb = recvBufferCreate(maxlinelen); // maybe too long ??
tmp->print = print; // print function
tmp->error_occurred = 0; // no errors

// CREATE SOCKET

if ( ( tmp->socket = sockopen( hostname , anyaddress , port ) ) == -1 )
	{
	
	sock_error("sockopen",-1,tmp);
	}

// get server infos
get_info(tmp);
sprintf(infostring,"Ip address %s real port %ld",tmp->ipaddress,tmp->realport);
sock_info(infostring,tmp);

// <- WELCOME
sock_receive(tmp, tmp->welcomestring, maxlinelen);

return(tmp);
}

void sock_disconnect(struct sock_state_t *server)
{
if ( sockclose( server->socket ) == -1 )
	sock_error("socketclose",-1,server);
	
recvBufferDestroy(server->prb);
free(server->ipaddress);
free(server->welcomestring);
free(server->hostname);
free(server);
}


struct sock_state_t * sock_bind(struct in_addr bind_add, unsigned short port,
		int maxlinelen,void (*print)(char *))
{
struct sock_state_t *tmp;
char infostring[]="Ip address xxx.xxx.xxx.xxx real port xxxxx";

tmp = (struct sock_state_t *) malloc(sizeof(struct sock_state_t));
if(tmp == NULL)
	return NULL;
	
tmp->maxlinelen = maxlinelen;
tmp->hostname  = strdup("localhost");
tmp->ipaddress = strdup("255.255.255.255");
tmp->welcomestring = NULL;
tmp->prb = recvBufferCreate(maxlinelen); // maybe too long ??
tmp->print = print; // print function
tmp->error_occurred = 0; // no errors

// CREATE SOCKET
tmp->socket = sockopen( NULL , bind_add , port);
	
if ( tmp->socket == -1 )
	{
	sock_error("sockopen",-1,tmp);
	fprintf(stderr,"Unable to bind on %s:%u\n",inet_ntoa(bind_add),port);
	free(tmp);
	exit(1);
	}

//GET INFOS
get_info(tmp);
sprintf(infostring,"Ip address %s real port %ld",tmp->ipaddress,tmp->realport);
sock_info(infostring,tmp);

//listen
if (listen(tmp->socket, 5) == -1) {
		sockerror("socklisten(listen)");
		exit(0);
	}

return (tmp);
}

struct sock_state_t * sock_listen(struct sock_state_t * s)
{
struct sockaddr sockaddr;
int addrlen = sizeof(sockaddr);
int newsock;

memset(&sockaddr, 0, sizeof(sockaddr));
newsock = accept(s->socket, &sockaddr, &addrlen);
	
if (newsock != -1) 
	{
	struct sock_state_t* tmp;
	char infostring[]="Ip address xxx.xxx.xxx.xxx real port xxxxx";
				
	//create the new Servet_State_t
	tmp = (struct sock_state_t *) 
		malloc(sizeof(struct sock_state_t));
	MALLOC_CHECK(tmp);
	
	tmp->maxlinelen = s->maxlinelen;
	tmp->hostname  = strdup("localhost");
	tmp->ipaddress = strdup("255.255.255.255");
	tmp->welcomestring = NULL;
	tmp->prb = recvBufferCreate(tmp->maxlinelen); 
	tmp->print = s->print; // print function
	tmp->error_occurred = 0; // no errors
	tmp->socket = newsock;
	get_info(tmp);
		
	sprintf(infostring,"Ip address %s real port %ld",
		tmp->ipaddress,tmp->realport);
	sock_info(infostring,tmp);

	return tmp;
        } 
else 	{
	sockerror("socklisten(accept)");
	return NULL;
	}
}

