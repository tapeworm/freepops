/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://freepops.sf.net)                     *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	lua bindings for portablesocket
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <string.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"
#include "socketcommon.h"
#include "luabind.h"

#define METANAME "sockstate.type"
#define BUFSIZE 2048

// returns and checks a stringhack from the stack
static struct sock_state_t* check_sockstate(lua_State*L)
{
  void* tmp = luaL_checkudata(L,1,METANAME);
  luaL_argcheck(L,tmp != NULL,1,"sockstate expected");
  return *(struct sock_state_t**)tmp;
}

static void fake_print(char*s) { }

/* function: connect */
static int lua_psock_connect(lua_State* L)
{
struct sock_state_t** s;
struct sock_state_t* tmp;
const char* host;
int port;

L_checknarg(L,2,"connect wants 'host' and 'port'");
	
host = luaL_checkstring(L,1);
port = luaL_checkint(L,2);

tmp = sock_connect((char*)host,port,BUFSIZE*2,fake_print);

if(tmp == NULL || sock_error_occurred(tmp)) {
	lua_pushnil(L);
	return 1;
}

s = lua_newuserdata(L,sizeof(struct sock_state_t*));
luaL_getmetatable(L,METANAME);
lua_setmetatable(L,-2);

*s = tmp;

return 1;
}

static int lua_psock_send(lua_State* L) {
struct sock_state_t* tmp = check_sockstate(L);
const char* data = luaL_checkstring(L,2);
int rc;

L_checknarg(L,2,"send wants 'data'");

rc = sock_send(tmp,(char*)data);

lua_pushnumber(L,rc);

return 1;
}

static int lua_psock_recv(lua_State* L) {
struct sock_state_t* tmp = check_sockstate(L);	
char b[BUFSIZE]="";
int rc;

L_checknarg(L,1,"recv wants no arguments");

rc = sock_receive(tmp,b,BUFSIZE);

if(rc < 0) 
	lua_pushnil(L);
else
	lua_pushstring(L,b);

return 1;
}

static int lua_psock_disconnect(lua_State* L) {
struct sock_state_t* tmp = check_sockstate(L);

sock_disconnect(tmp);

return 0;
}

static const struct luaL_reg psock_f [] = {
  {"connect",lua_psock_connect},
  {NULL,NULL}
};

static const struct luaL_reg psock_m [] = {
  {"send",lua_psock_send},
  {"recv",lua_psock_recv},
  {NULL,NULL}
};

/* Open function */
int luaopen_psock (lua_State*L)
{
luaL_newmetatable(L,METANAME);

lua_pushstring(L,"__gc");
lua_pushcfunction(L,lua_psock_disconnect);
lua_settable(L,-3);

lua_pushstring(L,"__index");
lua_pushvalue(L,-2);
lua_settable(L,-3);

luaL_openlib(L,NULL,psock_m,0);
luaL_openlib(L,"psock",psock_f,0);
	
return 1;
}
