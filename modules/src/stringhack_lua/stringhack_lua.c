/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	lua stringhack bidings
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/
#include <string.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"
#include "lstringhack.h"

#include "compat-5.1.h"

// returns and checks a stringhack from the stack
static struct strhack_t* check_strhack(lua_State*L)
{
  void* tmp = luaL_checkudata(L,1,"stringhack.type");
  luaL_argcheck(L,tmp != NULL,1,"str_hack expected");
  return (struct strhack_t*)tmp;
}

/* function: new_str_hack */
static int lua_stringhack_new_str_hack(lua_State* L)
{
struct strhack_t** s = lua_newuserdata(L,sizeof(struct strhack_t*));
luaL_getmetatable(L,"stringhack.type");
lua_setmetatable(L,-2);
*s = new_str_hack();
return 1;
}

/* function: delete_str_hack */
static int lua_stringhack_delete_str_hack(lua_State* L)
{
struct strhack_t* a = * (struct strhack_t**) check_strhack(L);
delete_str_hack(a);
return 0;
}

/* function: dothack */
static int lua_stringhack_dothack(lua_State* L)
{
struct strhack_t* a = * (struct strhack_t**) check_strhack(L);
const char * s = luaL_checkstring(L,2);

char * tmp = dothack(a,s);
lua_pushstring(L,tmp);
if (tmp != s)
	free(tmp);

return 1;
}

/* function: tophack */
static int lua_stringhack_tophack(lua_State* L)
{
struct strhack_t* a = * (struct strhack_t**) check_strhack(L);
const char * s = luaL_checkstring(L,2);
int n = luaL_checkint(L,3);

char * tmp = tophack(a,s,n);
lua_pushstring(L,tmp);
if (tmp != s)
	free(tmp);

return 1;
}

/* function: current_lines */
static int lua_stringhack_current_lines(lua_State* L)
{
struct strhack_t* a = * (struct strhack_t**) check_strhack(L);
lua_pushnumber(L,(lua_Number)current_lines(a));
return 1;
}

/* function: check_stop */
static int lua_stringhack_check_stop(lua_State* L)
{
struct strhack_t* a = * (struct strhack_t**) check_strhack(L);
int n = luaL_checkint(L,2);
lua_pushboolean(L,check_stop(a,n));
return 1;
}

static const struct luaL_reg stringhack_f [] = {
  {"new",lua_stringhack_new_str_hack},
  {NULL,NULL}
};

static const struct luaL_reg stringhack_m [] = {
  {"dothack",lua_stringhack_dothack},
  {"tophack",lua_stringhack_tophack},
  {"current_lines",lua_stringhack_current_lines},
  {"check_stop",lua_stringhack_check_stop},
  {NULL,NULL}
};

/* Open function */
int luaopen_stringhack (lua_State*L)
{
luaL_newmetatable(L,"stringhack.type");

lua_pushstring(L,"__gc");
lua_pushcfunction(L,lua_stringhack_delete_str_hack);
lua_settable(L,-3);

luaL_getmetatable(L,"stringhack.type");
lua_pushstring(L,"__index");
lua_pushvalue(L,-2);
lua_settable(L,-3);

luaL_openlib(L,NULL,stringhack_m,0);
luaL_openlib(L,"stringhack",stringhack_f,0);
	
return 1;
}
