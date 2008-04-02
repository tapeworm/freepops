/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	bindings for log
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

#include "log.h"
#define LOG_ZONE "LUA_LOG"

static char* lua_log_infos(lua_State* L){
lua_Debug ar;
char* infos;
size_t len;

if ( lua_getstack(L,1,&ar) == 0)
	luaL_error(L,"unable to get current function stack");
if ( lua_getinfo(L,"Sl",&ar) == 0)
	luaL_error(L,"unable to get infos about current function");

len = strlen(ar.source) + 15;
infos = calloc(len,sizeof(char));
MALLOC_CHECK(infos);

snprintf(infos,len,"(%s, %d) : %%s\n",ar.source,ar.currentline);

return infos;
}

static int lua_log_error_abort(lua_State* L)
{
const char* m = luaL_checkstring(L,1);
char* info;
char tmp[1000];
L_checknarg(L,1,"unlock wants 1 argument (string)");

info = lua_log_infos(L);
snprintf(tmp,1000,info,m);
ERROR_ABORT(tmp);
free(info);

return 0;
}

static int lua_log_error_print(lua_State* L)
{
const char* m = luaL_checkstring(L,1);
char* info;
char tmp[1000];
L_checknarg(L,1,"unlock wants 1 argument (string)");

info = lua_log_infos(L);
snprintf(tmp,1000,info,m);
ERROR_PRINT(tmp);
free(info);

return 0;
}

static int lua_log_dbg(lua_State* L)
{
const char* m = luaL_checkstring(L,1);
char* info;
L_checknarg(L,1,"unlock wants 1 argument (string)");

info = lua_log_infos(L);
DBG(info,m);
free(info);

return 0;
}

static int lua_log_say(lua_State* L)
{
const char* m = luaL_checkstring(L,1);
L_checknarg(L,1,"unlock wants 1 argument (string)");

SAY((char*)m);

return 0;
}

static const struct luaL_Reg log_f [] = {
  {"say",lua_log_say},
  {"dbg",lua_log_dbg},
  {"error_print",lua_log_error_print},
  {"error_abort",lua_log_error_abort},
  {NULL,NULL}
};

/* Open function */
int luaopen_log (lua_State* L)
{
luaL_register(L,"log",log_f);	
return 1;
}
