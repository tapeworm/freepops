/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://freepops.sf.net)                     *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	regexp bindings
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef FREEBSD
   #include <sys/types.h>
#endif
#include <regex.h>

#include "lua.h"
#include "lauxlib.h"

#include "luabind.h"

#define METANAME "regularep.t"

// returns and checks a stringhack from the stack
static regex_t * check_regularexp(lua_State*L)
{
  void* tmp = luaL_checkudata(L,1,METANAME);
  luaL_argcheck(L,tmp != NULL,1,METANAME" expected");
  return (regex_t *)tmp;
}

// creates a new object
static int regularexp_comp(lua_State *L) {
  const char *pattern;
  int res;
  regex_t *pr;
  
  L_checknarg(L,1,"regularexp.new wants one argument (string)");
	  
  pr = (regex_t *)lua_newuserdata(L, sizeof(regex_t));
  pattern = luaL_checkstring(L,1);

  res = regcomp(pr, pattern, REG_EXTENDED);
  
  if (res != 0) {
    size_t sz = regerror(res, pr, NULL, 0);
    char errbuf[sz];
    regerror(res, pr, errbuf, sz);
    lua_pushstring(L, errbuf);
    lua_error(L);
  }
  
  luaL_getmetatable(L,METANAME);
  lua_setmetatable(L, -2);
  return 1;
}

// matches every occurrence
static int regularexp_match(lua_State *L) {
int res = 0;
int nmatch = 0;
int max;
const char *text;
regex_t *pr;
regmatch_t pm[1]={{-1,-1}};

pr = check_regularexp(L);
text = luaL_checkstring(L,2);
max = luaL_optint(L,3,0);

max = max < 0 ? 0 : max;

lua_newtable(L);

while(res == 0 && (max == 0 || nmatch < max) ) {
	res = regexec(pr, text , 1, pm, 0);
	if (res == 0) {
		nmatch++;
		lua_pushlstring(L, text + pm->rm_so,pm->rm_eo - pm->rm_so);
		lua_rawseti(L, -2,nmatch);
		text += pm->rm_eo;
	}

}
luaL_setn(L,-1,nmatch);
return 1;
}

// iterates over the occurrences
static int regularexp_gmatch(lua_State *L) {
int res = 0;
int nmatch = 0;
int max;
size_t cur=0;
const char *text;
regex_t *pr;
regmatch_t pm[1]={{-1,-1}};

pr = check_regularexp(L);
text = luaL_checkstring(L,2);
luaL_checktype(L, 3, LUA_TFUNCTION);
max = luaL_optint(L,4,0);

max = max < 0 ? 0 : max;

while(res == 0 && (max == 0 || nmatch < max) ) {
	res = regexec(pr, text , 1, pm, 0);
	if (res == 0) {
		nmatch++;
		lua_pushvalue(L, 3);
		lua_pushnumber(L,cur + pm->rm_so);
		lua_pushnumber(L,cur + pm->rm_eo);
		lua_pushlstring(L, text + pm->rm_so,pm->rm_eo - pm->rm_so);
		lua_call(L, 3, 1);
		if (!lua_isnil(L,-1)) {
			res = 1;
		}
		lua_pop(L,1);
		
		text += pm->rm_eo;
		cur += pm->rm_eo;
	}

}
return 0;
}

static int regularexp_gc (lua_State *L) {
  regex_t *r = check_regularexp(L);
  if (r)
    regfree(r);
  return 0;
}

static const luaL_reg regularexpmeta[] = {
  {"match",   regularexp_match},
  {"gmatch",  regularexp_gmatch},
  {NULL, NULL}
};

/* Open the library */

static const luaL_reg regularexp[] = {
  {"new", regularexp_comp},
  {NULL, NULL}
};

int luaopen_regularexp(lua_State *L)
{
luaL_newmetatable(L,METANAME);

lua_pushstring(L,"__gc");
lua_pushcfunction(L,regularexp_gc);
lua_settable(L,-3);

lua_pushstring(L,"__index");
lua_pushvalue(L,-2);
lua_settable(L,-3);

luaL_openlib(L, NULL, regularexpmeta, 0);
luaL_openlib(L, "regularexp", regularexp, 0);

return 1;
}
