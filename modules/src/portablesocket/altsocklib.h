/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   altsocklib.h
  * \brief  Portable socket layer
  * \author Gerald Dueck
  * \author Andrew Lynch
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/



#ifndef _ALTSOCKLIB_H_
#define _ALTSOCKLIB_H_

#include <stdlib.h>

#if defined(WIN32) && !defined(CYGWIN)
    #include <winsock.h>
#else
	#include <sys/socket.h>
	#include <netinet/in.h>
	#include <arpa/inet.h>
#endif

/** @name Documentation can be foud here
 * <A HREF=http://flinflon.brandonu.ca/Dueck/1999/62306/sockets/Default.htm>
 * http://flinflon.brandonu.ca/Dueck/1999/62306/sockets/Default.htm</A><BR> 
 * But these functions must not be used directly, use the \ref socketcommon.h 
 * layer.
 * */
//@{
/** if host == NULL means to bind as a server on bind_add, =! NULL 
	resolves and connects */
int sockopen(char *host, struct in_addr bind_add, unsigned short port);
int sockinfo(int sock, char *info);
int sockclose(int sock);
int senddata(int socket, char *buffer, int length);
int senddata_raw(int socket,const char *buffer, int length);
int recvdata(int socket, char *buffer, int maxsize);
void sockerror(char *msg);

//! don't use this directly
typedef struct {
	char *recvbuffer;
	char *bufp;
	char *bufe;
	int   size;
} recvbuffer_t;

recvbuffer_t *recvBufferCreate(int size);
void recvBufferDestroy(recvbuffer_t *rb);
int recvstring(int socket, char *buffer, int maxsize, recvbuffer_t *r);
int recvstring_with_timeout(int socket, char *buffer, int maxsize, recvbuffer_t *r, int timeout);
int sendstring(int socket, char *string);
int sendstring_raw(int socket,const char *string);
#if defined(WIN32) && !defined(CYGWIN)
void sockinit();
#endif
//@}

#endif
