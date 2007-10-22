/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	statistics default callbacks and datastructure
 * Notes:
 *	
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <stdlib.h>

#include "stats.h"

void (*statistics_new_connection)(void) = NULL;

static long unsigned int connections = 0;
void statistics_new_connection_default(){
	// possible race condition, who cares
	connections++;
}
long unsigned int statistics_get_new_connection(){
	return connections;
}

#define REGISTER(name,r,p) {#name,r,p,statistics_get_##name}
#define STOP {NULL,stats_void,stats_void,NULL}

struct stats_functions_t stats_functions[] = {
	REGISTER(new_connection,stats_long_usigned_int,stats_void),
	STOP,
};
struct stats_types_t stats_types[] = {
	{"long unsigned int",stats_long_usigned_int},
	{"void", stats_void},
	{NULL, stats_notype},
};
