/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   stats.h
  * \brief  stats 
  * 
  * \author Name <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/
#ifndef _STATS_H
#define _STATS_H

#define STATS_SESSION_CREATED 		(1 << 0)
#define STATS_SESSION_OK 			(1 << 1)
#define STATS_SESSION_ERR 		(1 << 2)
#define STATS_CONNECTION_ESTABLISHED 	(1 << 3)

#define STATS_ALL (STATS_SESSION_CREATED|STATS_SESSION_OK|STATS_SESSION_ERR|STATS_CONNECTION_ESTABLISHED)

void stats_activate(long unsigned int mask);

void (*stats_log_session_created)(void);
void (*stats_log_session_ok)(void);
void (*stats_log_session_err)(void);
void (*stats_log_connection_established)(void);

#define STATS_LOG(name,params...) if (stats_log_##name) stats_log_##name(params)

#endif
