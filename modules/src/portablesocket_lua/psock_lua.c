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

#include "log.h"
#define LOG_ZONE "psock"

#define METANAME "sockstate.type"
#define BUFSIZE 2048

#define DBG_NONE (0<<0)
#define DBG_SEND (1<<0)
#define DBG_RECV (1<<1)
#define DBG_INFO (1<<2)
#define DBG_ALL (DBG_INFO|DBG_RECV|DBG_SEND)

#define IS_ACTIVE(a) ((a) & (debug_opt))
#define BEGIN_WITH(s,a) (!strncmp((s),(a),strlen(a)))

// only one debug mode for the whole library...
// FIXME write more selective_print and choose the right one or add extra 
// parameter to print in the sockets..
static int debug_opt = DBG_NONE;

// returns and checks a stringhack from the stack
static struct sock_state_t* check_sockstate(lua_State*L)
{
  void* tmp = luaL_checkudata(L,1,METANAME);
  luaL_argcheck(L,tmp != NULL,1,"sockstate expected");
  return *(struct sock_state_t**)tmp;
}

// prints only selected messages (third connect parameter)
static void selective_print(char*s) { 
	if (BEGIN_WITH(s,SOCK_ERROR)) {
		ERROR_PRINT(s);
	} else if (IS_ACTIVE(DBG_INFO) && BEGIN_WITH(s,SOCK_INFO)) {
		DBG("%s",s);
	} else if (IS_ACTIVE(DBG_SEND) && BEGIN_WITH(s,SOCK_SENT)) {
		DBG("%s",s);
	} else if (IS_ACTIVE(DBG_RECV) && BEGIN_WITH(s,SOCK_RECEIVED)) {
		DBG("%s",s);
	}
}

/* function: connect */
static int lua_psock_connect(lua_State* L)
{
struct sock_state_t** s;
struct sock_state_t* tmp;
const char* host;
int port;
int flag;

L_checknarg(L,3,"connect wants 'host', 'port' and 'flag'");
	
host = luaL_checkstring(L,1);
port = luaL_checkint(L,2);
flag = luaL_checkint(L,3);

tmp = sock_connect((char*)host,port,BUFSIZE*2,selective_print);

if(tmp == NULL || sock_error_occurred(tmp)) {
	lua_pushnil(L);
	return 1;
}

s = lua_newuserdata(L,sizeof(struct sock_state_t*));
luaL_getmetatable(L,METANAME);
lua_setmetatable(L,-2);

*s = tmp;

debug_opt = flag;

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

static const struct L_const psock_c [] = {
  {"SEND",DBG_SEND},
  {"RECV",DBG_RECV},
  {"ALL",DBG_ALL},
  {"INFO",DBG_INFO},
  {"NONE",DBG_NONE},
  {NULL,0}
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
L_openconst(L,psock_c);
	
return 1;
}
