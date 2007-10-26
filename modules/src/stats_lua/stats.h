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
#define STATS_SESSION_OK 		(1 << 1)
#define STATS_SESSION_ERR 		(1 << 2)
#define STATS_CONNECTION_ESTABLISHED 	(1 << 3)
#define STATS_COOKIES			(1 << 4)

#define STATS_ALL 	(STATS_SESSION_CREATED|STATS_SESSION_OK|STATS_SESSION_ERR|\
			 STATS_CONNECTION_ESTABLISHED|STATS_COOKIES)

void stats_activate(long unsigned int mask);

#define STATS_DECLARE_INCR(name) void (*stats_log_##name)(void)

STATS_DECLARE_INCR(session_created);
STATS_DECLARE_INCR(session_ok);
STATS_DECLARE_INCR(session_err);
STATS_DECLARE_INCR(connection_established);

#define STATS_DECLARE_SUM(name) void(*stats_log_##name)(long int)

STATS_DECLARE_SUM(cookies);

#define STATS_LOG(name,params...) if (stats_log_##name) stats_log_##name(params)

#endif
