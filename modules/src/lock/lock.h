/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   lock.h
  * \brief  Implements locking function
  * \author Simone Vellei <simone_vellei@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef _LOCK_H_
#define _LOCK_H_

/**
 * \brief Try to unlock liberopops user mailbox
 * \param user the username
 * \param domain user mail domain
 * \param timeout time of lock length
 * \return 1 on success 0 otherwise
 */

int mailbox_unlock(char *user, char *domain, int timeout);


#endif
