/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   popserver.h
  * \brief  Pop3 server with driver support and multiple threads
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef POPSERVER_H
#define POPSERVER_H

#ifndef WIN32
	#include <sys/types.h>
	#include <netinet/in.h>
#else
	#include <winsock.h>
	#define uid_t int
	#define gid_t int
#endif

#include "popstate.h"

//! \name Error codes
//@{
#define POPSERVER_ERR_OK 	0
#define POPSERVER_ERR_SYNTAX 	1
#define POPSERVER_ERR_NETWORK 	2
#define POPSERVER_ERR_AUTH 	3
#define POPSERVER_ERR_INTERNAL 	4
#define POPSERVER_ERR_NOMSG 	5
#define POPSERVER_ERR_LOCKED 	6
#define POPSERVER_ERR_EOF 	7
#define POPSERVER_ERR_TOOFAST	8
#define POPSERVER_ERR_UNKNOWN 	9
//@}

/**
 * \brief These functions are called by the pop3 server
 *
 * \param buffer must be set to a memory region allocated
 * 	dinamically and must be freed by the popserver after sending it
 * 	to the client.
 * 	Multiline answr must have this form
 * 	"line_1\r\nline_2\r\n.....line_n\r\n"
 * \param p is always the same and may be used to decide what to do
 * \return is 0 on success, see the defines for specific error codes.
 *     
 */ 
struct popserver_functions_t
	{
	//! called when the client sends username
	int (*user)(struct popstate_t*p,char* username);
	//! called when the client sends password
	int (*pass)(struct popstate_t*p,char* password);
	//! called to trucate a section with no mailbox update
	int (*quit)(struct popstate_t*p);
	//! called to quit updating mailbox status
	int (*quit_update)(struct popstate_t*p);
	//! retrive first lines of message, must use the calback 
	int (*top)(struct popstate_t*p,long int msg,long int lines,void* data);
	//! retrive the full message, should use the callback
	int (*retr)(struct popstate_t*p,int msg,void* data);
	/*! \brief summarize mailbox status
	 *  \param messages will be set to the number of messages in the mailbox
	 *  \param size the quota of disk used by the mailbox in octects
	 */ 
	int (*stat)(struct popstate_t*p,int *messages,int* size);
	//! get the UIDL of the message msg
	int (*uidl)(struct popstate_t*p,int msg,char **buffer);
	//! get all uidls, each line is "msg_number uidl\r\n"
	int (*uidl_all)(struct popstate_t*p,char **buffer);
	//! list a mesage (print the size)
	int (*list)(struct popstate_t*p,int msg,char **buffer);
	//! lists all messages, each line is "msg_number size\r\n"
	int (*list_all)(struct popstate_t*p,char **buffer);
	//! resets the mailbox to the initial state
	int (*rset)(struct popstate_t*p);
	//! marks for deletion the message
	int (*dele)(struct popstate_t*p,int msg);
	//! prevents the timeout
	int (*noop)(struct popstate_t*p);

	/* \brief pointer to a function that creates the "other" 
	 * fields in struct popstate_t */
	//void *(*new_other)(void);
	/*! \brief pointer to a function that deletes the "other" 
	 * fields in struct popstate_t */
	void (*delete_other)(void *);
	};

/*! 
 * \brief Starts a pop3 server that uses functions in f and listens on port port
 * \param set_rights a function to loose rights called after bind(). 
 * 	This function must return 0 on success.
 * \param maxthreads Upper bound to thread launched to manage incoming 
 * 	connections.
 * 
 */ 
void popserver_start(struct popserver_functions_t* f, 
	struct in_addr address, unsigned short port, int maxthreads,
	int(*set_rights)(uid_t,gid_t),uid_t uid,gid_t gid);

/*!
 * \brief retr and top need this
 *
 * \param buffer is the data to send, \0 terminated
 * \param an opaque data pased by the popserver to retr/top
 */ 
int popserver_callback(char* buffer, void* popserver_data);

#endif

