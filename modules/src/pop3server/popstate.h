/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   popstate.h
  * \brief  Implement the session cache of the pop3 account
  * \author Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef POPSTATE_H
#define POPSTATE_H

//! the falg used for mailmessage deletion
#define MAILMESSAGE_DELETE	0x1

//! the falg used for popstate state
//#define POPSTATE_LOGIN		0x1
//#define POPSTATE_STAT		0x2

//! returns a new and empty structure
struct popstate_t *new_popstate_t();
void new_popstate_other(struct popstate_t *p,void *newp(void*),void* data);
//! free memory
void delete_popstate_t(struct popstate_t *p, void deletep(void *));
//! sets popstate password, string will be duplicated
void set_popstate_password(struct popstate_t *p,const char* passwd);
//! sets popstate username, string will be duplicated
void set_popstate_username(struct popstate_t *p,const char* username);
//! sets popstate nummessages, expanding/shrinking the data structure
void set_popstate_nummesg(struct popstate_t *p,int n);
//! sets popstate mailbox size (invalidates the DELE flagged hiding in the corresponding get_ function)
void set_popstate_boxsize(struct popstate_t *p,int n);
//! sets popstate flag
//void set_popstate_flag(struct popstate_t *p,int flag);
//! unsets popstate flag
//void unset_popstate_flag(struct popstate_t *p,int flag);
//! get if popstate flag is set
//int get_popstate_flag(struct popstate_t *p,int flag);
//! get popstate password, not strdupd
const char* get_popstate_password(struct popstate_t *p);
//! get popstate username, not strdupd
const char* get_popstate_username(struct popstate_t *p);
//! get popstate mailmessage i handler
struct mail_msg_t* get_popstate_mailmessage(struct popstate_t *p,int n);
//! get popstate number of messages
int get_popstate_nummesg(struct popstate_t *p);
int get_popstate_boxsize(struct popstate_t *p);
void* get_popstate_other(struct popstate_t *p);

//! sets mailmessage size
void set_mailmessage_size(struct mail_msg_t* m,int size);
//! sets mailmessage uidl, string will be duplicated
void set_mailmessage_uidl(struct mail_msg_t* m, const char* uidl);
//! sets mailmessage flag
void set_mailmessage_flag(struct mail_msg_t* m,int flag);
//! unsets mailmessage flag
void unset_mailmessage_flag(struct mail_msg_t* m,int flag);
//! get mailmessage size
int get_mailmessage_size(struct mail_msg_t* m);
//! get if mailmessage flag is set
int get_mailmessage_flag(struct mail_msg_t* m,int flag);
//! get mailmessage uidl, not strdupd
const char* get_mailmessage_uidl(struct mail_msg_t* m);


#endif
