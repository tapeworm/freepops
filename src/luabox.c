/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)					*
 * This file is distributed under the terms of GNU GPL license.			   *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *		lua VM generation stuff
 * Notes:
 *
 * Authors:
 *		Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "luay.h"

#include "luabox.h"

#include "pop3server_lua.h"
#include "log_lua.h"
#include "mlex_lua.h"
#include "stringhack_lua.h"
#include "session_lua.h"
#include "lua-curl.h"
#include "getdate_lua.h"
#include "psock_lua.h"
#include "base64_lua.h"
#include "regularexp_lua.h"
#include "lxplib.h"
#include "crypto_lua.h"
#include "lfs.h"
#include "dpipe_lua.h"

#include "log.h"
#define LOG_ZONE "LUABOX"

struct entry_t { const char* name; int (*open)(lua_State*); }; 
static struct entry_t libs[LUABOX_LAST] = {
		{"pop3server",luaopen_pop3server},
		{"mlex",luaopen_mlex},
		{"stringhack",luaopen_stringhack},
		{"session",luaopen_session},
		{"curl",luaopen_curl},
		{"psock",luaopen_psock},
		{"base64",luaopen_base64},
		{"getdate",luaopen_getdate},
		{"regularexp",luaopen_regularexp},
		{"lxp",luaopen_lxp},
		{"log",luaopen_log},
		{"crypto",luaopen_crypto},
		{"lfs",luaopen_lfs},
		{"dpipe",luaopen_dpipe},
};

lua_State* luabox_genbox(unsigned long intial_stuff){
	lua_State* box = lua_open();
	int i;
	MALLOC_CHECK(box);
	// add stdlibs
	lua_gc(box, LUA_GCSTOP, 0);
	luaL_openlibs(box);
	lua_gc(box, LUA_GCRESTART, 0);
	// set package.preload
	lua_getglobal(box,"package");
	lua_getfield(box,-1,"preload");
	for ( i = 0 ; i < LUABOX_LAST ; i++) {
		lua_pushcfunction(box,libs[i].open);
		lua_setfield(box,-2,libs[i].name);
	}
	luay_emptystack(box);		
	luabox_addtobox(box,intial_stuff);
	return box;
}

void luabox_addtobox(lua_State* box,unsigned long stuff){
	long int i;
	for ( i = 0 ; i < LUABOX_LAST ; i++) {
		int j = 1<<i;
		if (j & stuff) {
			luay_call(box,"s|","require", libs[i].name);
			luay_emptystack(box);		
		}
	}
}
