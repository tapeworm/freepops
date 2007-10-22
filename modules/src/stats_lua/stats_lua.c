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

#include "log.h"
#define LOG_ZONE "LUA_STATS"

static enum stats_type_e type_of_string(const char* s){
	int i;
	if (s == NULL) return stats_notype;
	for (i=0; stats_types[i].name != NULL; i++){
		if (!strcmp(s,stats_types[i].name)) 
			return stats_types[i].type;
	}
	return stats_notype;
}

static const char * string_of_type(enum stats_type_e t){
	int i;
	for (i=0; stats_types[i].name != NULL; i++){
		if (stats_types[i].type == t) 
			return stats_types[i].name;
	}
	ERROR_PRINT("This should never happen, missing type %d in stats_types\n",(int)t);
	return NULL;
}


static const struct luaL_reg empty_reg[] = {
 {NULL,NULL}
};

static int generic_function(lua_State* L){
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
