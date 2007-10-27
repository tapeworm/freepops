/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   session.h
  * \brief  persistency of user session data
  * 
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/

#ifndef SESSION_H
#define SESSION_H
/**
 * \brief saves (k,data) in the sessions storage
 *
 * \return 0 on success
 */ 
int  session_save(const char* key,const char* data,int overwrite);
//! NULL means not foud, "\a" means locked
const char* session_load_and_lock(const char* key);
void  session_remove(const char* key);
void  session_unlock(const char* key);
void  session_init(void);
#endif
