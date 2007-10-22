/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   statistics.h
  * \brief  a module for handling statistics
  * 
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/

#ifndef _STATS_H_
#define _STATS_H_

#define STATS_LOG(name,params...) \
	if (statistics_##name != NULL) statistics_##name(params)

#define STATS_ACTIVATE(name) statistics_##name = statistics_##name##_default

extern void (*statistics_new_connection)(void);
extern void statistics_new_connection_default(void);
extern long unsigned int statistics_get_new_connection();


enum stats_type_e {
	stats_long_usigned_int,
	stats_void,
	stats_notype,
};
struct stats_functions_t {
	const char *name;
	enum stats_type_e rettype;
	enum stats_type_e intype;
	void *fpointer;
};
struct stats_types_t {
	const char *name;
	enum stats_type_e type;
};

extern struct stats_functions_t stats_functions[];
extern struct stats_types_t stats_types[];

#endif
