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

#define LUI long unsigned int
#define LI long int
#define UI unsigned int

#define VOID_VOID_LOGGER(name) void (*stats_log_##name)(void)
#define VOID_LINT_LOGGER(name) void (*stats_log_##name)(LI)
#define VOID_LINT_ARRAY_LOGGER(name) void (*stats_log_##name)(UI)

#define LUINT(name) \
	HIDDEN LUI counter_##name; \
	HIDDEN LUI get_##name(){  return counter_##name; }\

#define LINT(name) \
	HIDDEN LI counter_##name; \
	HIDDEN LI get_##name(){  return counter_##name; }\

#define LUINT_INCR(name) \
	LUINT(name) \
	HIDDEN void stats_log_##name##_incr(){ counter_##name++; } 

#define LINT_SUM(name) \
	LINT(name) \
	HIDDEN void stats_log_##name##_sum(LI x) { counter_##name += x; }

#define ARRAY_INCR(name,top) \
	HIDDEN LUI counter_##name[top]; \
	HIDDEN LUI get_##name(UI x){  return counter_##name[x % top]; }\
	HIDDEN void stats_log_##name##_incr(UI x) { counter_##name[x % top]++; }

#define ACTIVATE(name,kind) stats_log_##name = stats_log_##name##_##kind;

VOID_VOID_LOGGER(session_created);
VOID_VOID_LOGGER(session_ok);
VOID_VOID_LOGGER(connection_established);
VOID_LINT_LOGGER(cookies);
VOID_LINT_ARRAY_LOGGER(session_err);

LUINT_INCR(session_created);
LUINT_INCR(session_ok);
LUINT_INCR(connection_established);
LINT_SUM(cookies);
ARRAY_INCR(session_err,10);

void stats_activate(long unsigned int mask){
	if (mask & STATS_SESSION_CREATED) ACTIVATE(session_created,incr); 
	if (mask & STATS_SESSION_OK) ACTIVATE(session_ok,incr);
	if (mask & STATS_SESSION_ERR) ACTIVATE(session_err,incr);
	if (mask & STATS_CONNECTION_ESTABLISHED) ACTIVATE(connection_established,incr);
	if (mask & STATS_COOKIES) ACTIVATE(cookies,sum);
}

/* ============================= LUA BINDINGS =============================== */

#define REGISTER(name,r,p) {#name,r,p,get_##name}
#define STOP {NULL,stats_void,stats_void,NULL}
#define CAST(t,x) ((t)x)
#define CALL(t1,f,t2,x) (CAST(t1 (*)(t2),f)(CAST(t2,x)))
#define CALLV(t1,f) (CAST(t1 (*)(void),f)())

HIDDEN const struct luaL_Reg empty_reg[] = {{NULL,NULL}};

enum stats_type_e {
	stats_long_usigned_int,
	stats_long_int,
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
	REGISTER(session_ok,stats_long_usigned_int,stats_void),
	REGISTER(cookies,stats_long_int,stats_void),
	REGISTER(session_err,stats_long_usigned_int,stats_long_usigned_int),
	STOP,
};

HIDDEN struct stats_types_t stats_types[] = {
	{"long unsigned int",stats_long_usigned_int},
	{"long int",stats_long_int},
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

	//DBG("Calling function %p : %s -> %s\n",f,intypes,rettypes);

	// I don't want to use libffi for the moment, lets do all possibilities
	switch(rettype) {
		case stats_long_usigned_int: {
			LUI rc=0;
			switch(intype) {
				case stats_long_usigned_int: rc = CALL(LUI,f,LUI,lua_tonumber(L,-1)); break;
				case stats_long_int:         rc = CALL(LUI,f,LI,lua_tonumber(L,-1)); break;
				case stats_void:             rc = CALLV(LUI,f); break;
				case stats_notype:
					ERROR_PRINT("Function %p with no intype\n",f);
					return 0;
				break;
			}
			lua_pushnumber(L,rc);
			break;
		}
		case stats_long_int: {
			LI rc=0;
			switch(intype) {
				case stats_long_usigned_int: rc = CALL(LI,f,LUI,lua_tonumber(L,-1)); break;
				case stats_long_int:         rc = CALL(LI,f,LI,lua_tonumber(L,-1)); break;
				case stats_void:             rc = CALLV(LI,f); break;
				case stats_notype:
					ERROR_PRINT("Function %p with no intype\n",f);
					return 0;
				break;
			}
			lua_pushnumber(L,rc);
			break; 
		}
		case stats_void:
			switch(intype) {
				case stats_long_usigned_int: CALL(void,f,LUI,lua_tonumber(L,-1)); break;
				case stats_long_int:         CALL(void,f,LI,lua_tonumber(L,-1)); break;
				case stats_void:             CALLV(void,f); break;
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

luaL_register(L,"stats",empty_reg);	

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
