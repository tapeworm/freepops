/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	bindings for session
 * Notes:
 *
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <lua.h>
#include <lauxlib.h>

#include "string.h"
#include "session.h"

#define OVERWRITE 1
#define FAILIFPRESENT 0

static void L_error(lua_State* L, char* msg, ...){
char buffer[1024];
va_list ap;
	
va_start(ap,msg);
vsnprintf(buffer,1024,msg,ap);
va_end(ap);

luaL_error(L,buffer);
}

static void L_checknarg(lua_State* L,int n,char* msg){
if( lua_gettop(L) != n )
	L_error(L,"Stack has %d values: '%s'",lua_gettop(L),msg);
}

/* function: session_save */
static int lua_session_save(lua_State* L)
{
const char* key = luaL_checkstring(L,1);
const char* data = luaL_checkstring(L,2);
int overwrite = luaL_checkint(L,3);
L_checknarg(L,3,"save wants 3 argument (string,string,flag)");

if ( overwrite != OVERWRITE && overwrite != FAILIFPRESENT)
	L_error(L,"the thisrd argument for save must be one of: "
		"OVERWRITE, FAILIFPRESENT");

session_save(key,data,overwrite);

return 0;
}

/* function: session_load_and_lock */
static int lua_session_load_lock(lua_State* L)
{
const char* key =  luaL_checkstring(L,1);
const char* ret;
L_checknarg(L,1,"load_and_lock wants 1 argument (string)");

ret = session_load_and_lock(key);

lua_pushstring(L,ret);

return 1;
}

/* function: session_remove */
static int lua_session_remove(lua_State* L)
{
const char* key = luaL_checkstring(L,1);
L_checknarg(L,1,"remove wants 1 argument (string)");

session_remove(key);

return 0;
}

/* function: session_unlock */
static int lua_session_unlock(lua_State* L)
{
const char* key = luaL_checkstring(L,1);
L_checknarg(L,1,"unlock wants 1 argument (string)");

session_unlock(key);

return 0;
}

static const struct luaL_reg session_f [] = {
  {"save",lua_session_save},
  {"remove",lua_session_remove},
  {"unlock",lua_session_unlock},
  {"load_lock",lua_session_load_lock},
  {NULL,NULL}
};

/* Open function */
int luaopen_session (lua_State* L)
{
luaL_openlib(L,"session",session_f,0);	
lua_pushstring(L,"OVERWRITE");
lua_pushnumber(L,(lua_Number)OVERWRITE);
lua_settable(L,-3);	 
lua_pushstring(L,"FAILIFPRESENT");
lua_pushnumber(L,(lua_Number)FAILIFPRESENT);
lua_settable(L,-3);
return 1;
}
