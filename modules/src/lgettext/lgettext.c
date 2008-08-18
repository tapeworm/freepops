#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include <libintl.h>
#include <locale.h>

extern int _nl_msg_cat_cntr;

/*** Prototypes ***/

LUA_API int luaopen_lgettext(lua_State *);

/*** Methods ***/

static int
lua_gettext_translate(lua_State *L)
{
  lua_pushstring(L, gettext(luaL_checkstring(L, 1)));

  return(1);
}

const luaL_reg gettext_methods[] = {
  {"translate",   lua_gettext_translate },
  {NULL, NULL}
};

/*** REGISTER ***/

LUA_API int
luaopen_lgettext(lua_State *L)
{
  luaL_openlib(L, "gettext", gettext_methods, 0);

  return(1);
}
