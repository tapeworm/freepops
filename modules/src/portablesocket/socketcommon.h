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
#if !(defined(WIN32) && !defined(CYGWIN))
	#include <netinet/in.h>
#else
	#include <winsock.h>
#endif

#include "altsocklib.h"
#include "win32_compatibility.h"

struct sock_state_t;

extern int sock_error_occurred(struct sock_state_t *s);

/** @name strings prepended to log lines
 *
 */ 

//@{
#define SOCK_ERROR 		"!! "
#define SOCK_INFO 		"?? "
#define SOCK_SENT 		"-> "
#define SOCK_RECEIVED 		"<- "
//@}

/*****************************************************************************/

/** @name Communication functions
 *  These are for sending and receiveing. sending return 0 if ok, negative 
 *  if error, receiving return # received byte or negative if error */

//@{
//! send buffer on s, remember that "\r\n" will be appended to buffer
extern int sock_send(struct sock_state_t *s,char* buffer);
//! send buffer on s, with no "\r\n" at the end
extern int sock_sendraw(struct sock_state_t *s,const char* buffer);
//! send a non \0 terminated buffer of len l on s, with no "\r\n" at the end 
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
