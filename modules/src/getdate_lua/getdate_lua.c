/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	getdate lua bindings
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/
#include <lauxlib.h>
#include <lua.h>

#include "getdate.h"

static int L_getdate(lua_State* L){
const char * s = luaL_checkstring(L,1);
long int rc;

if( lua_gettop(L) != 1 )
	luaL_error(L,"getdate wnats only one argument (string)");

rc = gd_getdate(s,NULL);

lua_pushnumber(L,rc);

return 1;
}

static const struct luaL_reg getdate_f [] = {
  {"toint",L_getdate},
  {NULL,NULL}
};

int luaopen_getdate(lua_State* L) {
	
	luaL_openlib(L,"getdate",getdate_f,0);

	return 1;
}

