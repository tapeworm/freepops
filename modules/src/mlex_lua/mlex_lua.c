#include <string.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"
#include "mlex.h"
#include "list.h"

#include "compat-5.1.h"

// returns and checks a stringhack from the stack
static void** check_mlex(lua_State*L)
{
  void* tmp = luaL_checkudata(L,1,"mlex.type");
  luaL_argcheck(L,tmp != NULL,1,"mlex expected");
  return (void**)tmp;
}

static int lua_mlex_match(lua_State* L)
{
char* data = ((char*)  luaL_checkstring(L,1));
char* exp = ((char*)  luaL_checkstring(L,2));
char* ret = ((char*)  luaL_checkstring(L,3));
list_t* m = mlmatch(data,exp,ret);

list_t** r=NULL;
char**   c=NULL;

/* hack: the userdata is 2 pointer long, so we will use a +1 to get the 
 * string that is stored in the second position
 */ 
void** s = lua_newuserdata(L,sizeof(list_t*)+sizeof(char *));
luaL_getmetatable(L,"mlex.type");
lua_setmetatable(L,-2);

r = (list_t**)s;
c = (char**)s+1;

*r = m;
*c = strdup(data);

//printf("userdata e' %p,r=%p c=%p,risultato=%p,*r=%p,*c=%s",s,r,c,m,*r,*c);

return 1;
}

/* function: mlmatch_print_results */
static int lua_mlex_print(lua_State* L)
{
void** s = check_mlex(L);
list_t* r=*((list_t**)s);
char*   c=*((char**)s+1);

//printf("userdata e' %p, r=%p c=%p, c=%s",s,r,c,c);
mlmatch_print_results(r,c);
return 0;
}

/* function: mlmatch_free_results */
static int lua_mlex_free(lua_State* L)
{
void** s = check_mlex(L);
list_t* r=*((list_t**)s);
char*   c=*((char**)s+1);

mlmatch_free_results(r);
free(c);

return 0;
}

/* function: mlmatch_get_result */
static int lua_mlex_get(lua_State* L)
{
void** s = check_mlex(L);
list_t* r=*((list_t**)s);
char*   c=*((char**)s+1);
int x = luaL_checkint(L,2);
int y = luaL_checkint(L,3);

char* ret = mlmatch_get_result(x,y,r,c);
if (ret == NULL) {
	lua_pushnil(L);
} else {
	lua_pushstring(L,(const char*)ret);
	free((char*)ret);
}
return 1;
}

/* function: list_len */
static int lua_mlex_count(lua_State* L)
{
void** s = check_mlex(L);
list_t* r=*((list_t**)s);
//char*   c=*((char**)s+1);
int ret = (int)  list_len(r);
lua_pushnumber(L,(lua_Number)ret);
return 1;
}

static const struct luaL_reg mlex_f [] = {
  {"match",lua_mlex_match},
  {NULL,NULL}
};

static const struct luaL_reg mlex_m [] = {
  {"print",lua_mlex_print},
  {"get",lua_mlex_get},
  {"count",lua_mlex_count},
  {NULL,NULL}
};


/* Open function */
int luaopen_mlex (lua_State*L)
{
luaL_newmetatable(L,"mlex.type");

lua_pushstring(L,"__gc");
lua_pushcfunction(L,lua_mlex_free);
lua_settable(L,-3);

luaL_getmetatable(L,"mlex.type");
lua_pushstring(L,"__index");
lua_pushvalue(L,-2);
lua_settable(L,-3);

luaL_openlib(L,NULL,mlex_m,0);
luaL_openlib(L,"mlex",mlex_f,0);
	
return 1;
}
