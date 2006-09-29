/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	base64 encoding lua bindings
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/
#include <string.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"
#include "base64.h"

static int lua_base64_encode(lua_State* L)
{
const char * s = luaL_checkstring(L,1);

char * tmp = base64enc_raw(s,lua_strlen(L,1));
lua_pushstring(L,tmp);
if (tmp != s)
	free(tmp);

return 1;
}

static int lua_base64_decode(lua_State* L)
{
const char * s = luaL_checkstring(L,1);

char * tmp = base64dec(s,lua_strlen(L,1));
lua_pushstring(L,tmp);
if (tmp != s)
	free(tmp);

return 1;
}

static const struct luaL_reg stringhack_f [] = {
  {"encode",lua_base64_encode},
  {"decode",lua_base64_decode},
  {NULL,NULL}
};

/* Open function */
int luaopen_base64 (lua_State*L)
{

luaL_openlib(L,"base64",stringhack_f,0);
	
return 1;
}
