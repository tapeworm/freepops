/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   socketcommon.h
  * \brief  Wrap functions for altsocklib
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/

#ifndef SOCKET_COMMON_H
#define SOCKET_COMMON_H

#include <pthread.h>
#ifndef WIN32
	#include <netinet/in.h>
#else
	#include <winsock.h>
#endif

#include "altsocklib.h"
#include "win32_compatibility.h"

/** @name strings prepended to log lines
 *
 */ 

//@{
#define SOCK_ERROR 		"!! "
#define SOCK_INFO 		"?? "
#define SOCK_SENT 		"-> "
#define SOCK_RECEIVED 		"<- "
//@}

/**
 *   A generic server state
 *
 *
 */ 
struct sock_state_t
	{
	//! the socket handler
	 int socket;
	//! hostname
	 char *hostname;
	//! NULL if listening, othewise the welcome string
	 char *welcomestring;
	//! string with the IP in xxx.xxx.xxx.xxx form
	 char *ipaddress;
	//! real port
	 unsigned long realport;
	//! buffer for altsocklib
	 recvbuffer_t *prb;
	//! function used for debug printing
	 void (*print)(char *);
	//! flag used to inhibit commands
	 int error_occurred;
	//! line len
	 int maxlinelen;
	};

/*****************************************************************************/
	
/** @name Function for logging
 *  All these functions are used internally by socketcommon,
 *  but can be used to make erta loggin outside this module.  */

//@{
//! generic print on log file
extern void sock_print(char *prebuffer,char *buffer,struct sock_state_t *s);
//! error print on log file
extern void sock_error(char *type,int ernum,struct sock_state_t *s);
//! received print on log file
extern void sock_received(char *buffer,struct sock_state_t *s);
//! sent print on log file
extern void sock_sent(char *buffer,struct sock_state_t *s);
//! info print on log file
extern void sock_info(char *buffer,struct sock_state_t *s);
//@} 

/*****************************************************************************/

/** @name Communication functions
 *  These are for sending and receiveing.  */

//@{
//! send buffer on s, remember that "\r\n" will be appended to buffer
extern void sock_send(struct sock_state_t *s,char* buffer);
//! send buffer on s, with no "\r\n" at the end
extern void sock_sendraw(struct sock_state_t *s,char* buffer);
//! receive maxlen into buffer with "\r\n" stripped
extern int  sock_receive(struct sock_state_t *s,char* buffer,int maxlen);
//! receive with timeout in seconds
extern int  sock_receive_with_timeout(struct sock_state_t *s,char* buffer,int maxlen, int timeout);
//@}

/*****************************************************************************/

/**  @name Client/Server functions
 *   These are for starting a client or a server.  */

//@{
//! connect to a server 
extern struct sock_state_t * sock_connect(char *hostname,unsigned long port,int maxlinelen,void (*print)(char *));
//! close the socket and free the structure s
extern void sock_disconnect(struct sock_state_t *s);
//! bind a socket and listen on it
extern struct sock_state_t * sock_bind(struct in_addr bind_add,unsigned short port,int maxlinelen,void (*print)(char *));
//! this is the accept, returns the new socket that must be freed by the caller
extern struct sock_state_t *  sock_listen(struct sock_state_t * s);
//@}

#endif
