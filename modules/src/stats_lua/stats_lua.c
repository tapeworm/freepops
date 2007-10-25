/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	bindings for stats
 * Notes:
 *
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <lua.h>
#include <lauxlib.h>

#include <string.h>
#include <stdio.h>

#include "luabind.h"
#include "luay.h"
#include "stats.h"
#include "stats_lua.h"

#include "log.h"
#define LOG_ZONE "LUA_STATS"

#define HIDDEN static

#define VOID_VOID_LOGGER(name) void (*stats_log_##name)(void)

VOID_VOID_LOGGER(session_created);
VOID_VOID_LOGGER(session_ok);
VOID_VOID_LOGGER(session_err);
VOID_VOID_LOGGER(connection_established);

#define LONG_INT_COUNTER(name) \
	HIDDEN long unsigned int counter_##name; \
	HIDDEN long unsigned int get_##name(){  return counter_##name; }\
	HIDDEN void stats_log_##name##_fun(){ counter_##name++; } 

LONG_INT_COUNTER(session_created);
LONG_INT_COUNTER(session_ok);
LONG_INT_COUNTER(session_err);
LONG_INT_COUNTER(connection_established);

#define ACTIVATE(name) stats_log_##name = stats_log_##name##_fun;

void stats_activate(long unsigned int mask){
	if (mask & STATS_SESSION_CREATED) ACTIVATE(session_created); 
	if (mask & STATS_SESSION_OK) ACTIVATE(session_ok);
	if (mask & STATS_SESSION_ERR) ACTIVATE(session_err);
	if (mask & STATS_CONNECTION_ESTABLISHED) ACTIVATE(connection_established);
}

/* ============================= LUA BINDINGS =============================== */

#define REGISTER(name,r,p) {#name,r,p,get_##name}
#define STOP {NULL,stats_void,stats_void,NULL}

HIDDEN const struct luaL_reg empty_reg[] = {{NULL,NULL}};

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

HIDDEN struct stats_functions_t stats_functions[] = {
	REGISTER(connection_established,stats_long_usigned_int,stats_void),
	REGISTER(session_created,stats_long_usigned_int,stats_void),
	REGISTER(session_err,stats_long_usigned_int,stats_void),
	REGISTER(session_ok,stats_long_usigned_int,stats_void),
	STOP,
};

HIDDEN struct stats_types_t stats_types[] = {
	{"long unsigned int",stats_long_usigned_int},
	{"void", stats_void},
	{NULL, stats_notype},
};

HIDDEN enum stats_type_e type_of_string(const char* s){
	int i;
	if (s == NULL) return stats_notype;
	for (i=0; stats_types[i].name != NULL; i++){
		if (!strcmp(s,stats_types[i].name)) 
			return stats_types[i].type;
	}
	return stats_notype;
}

HIDDEN const char * string_of_type(enum stats_type_e t){
	int i;
	for (i=0; stats_types[i].name != NULL; i++){
		if (stats_types[i].type == t) 
			return stats_types[i].name;
	}
	ERROR_PRINT("This should never happen\n");
	ERROR_PRINT("Missing type %d in stats_types\n",(int)t);
	return NULL;
}


HIDDEN int generic_function(lua_State* L){
	void * f = lua_touserdata(L,lua_upvalueindex(1));
	const char * rettypes = lua_tostring(L,lua_upvalueindex(2));
	const char * intypes = lua_tostring(L,lua_upvalueindex(3));
	enum stats_type_e rettype = type_of_string(rettypes);
	enum stats_type_e intype = type_of_string(intypes);

	DBG("Calling function %p : %s -> %s\n",f,intypes,rettypes);

	// I don't want to use libffi for the moment, lets do all possibilities
	switch(rettype) {
		case stats_long_usigned_int:
			switch(intype) {
				long unsigned int rc;
				case stats_long_usigned_int: 
					rc = ((long unsigned int (*)(long unsigned int))f)
						((long unsigned int)lua_tonumber(L,-1));
					lua_pushnumber(L,rc);
				break;
				case stats_void:
					rc = ((long unsigned int (*)(void))f)();
					lua_pushnumber(L,rc);
				break;
				case stats_notype:
					ERROR_PRINT("Function %p with no intype\n",f);
					return 0;
				break;
			}

		break;
		case stats_void:
			switch(intype) {
				case stats_long_usigned_int:
					((void (*)(long unsigned int))f)
						((long unsigned int)lua_tonumber(L,-1));
				break;
				case stats_void:
					((void (*)(void))f)();
				break;
				case stats_notype:
					ERROR_PRINT("Function %p with no intype\n",f);
					return 0;
				break;
			}
		break;
		case stats_notype:
			ERROR_PRINT("Function %p with no rettype\n",f);
			return 0;
		break;
	}

	return (rettype == stats_void) ? 0 : 1;
}

/* Open function */
int luaopen_stats (lua_State* L){
int i;

luaL_openlib(L,"stats",empty_reg,0);	

for (i=0; stats_functions[i].name != NULL; i++){
	lua_pushlightuserdata(L, stats_functions[i].fpointer);
	lua_pushstring(L,string_of_type(stats_functions[i].rettype));
	lua_pushstring(L,string_of_type(stats_functions[i].intype));
	//luay_printstack(L);
	lua_pushcclosure(L, generic_function, 3);
	lua_setfield(L, -2, stats_functions[i].name);
}

return 1;
}

/* vim:set ts=4: */
