#include <string.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"
#include "base64.h"

/* function: dothack */
static int lua_base64_encode(lua_State* L)
{
const char * s = luaL_checkstring(L,1);

char * tmp = base64enc(s);
lua_pushstring(L,tmp);
if (tmp != s)
	free(tmp);

return 1;
}

static const struct luaL_reg stringhack_f [] = {
  {"encode",lua_base64_encode},
  {NULL,NULL}
};

/* Open function */
int luaopen_base64 (lua_State*L)
{

luaL_openlib(L,"base64",stringhack_f,0);
	
return 1;
}
