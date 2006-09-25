/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	lua VM generation stuff
 * Notes:
 *
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
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

#include "log.h"
#define LOG_ZONE "LUABOX"

static int (*opening_functions[LUABOX_LAST])(lua_State*) = {
            luaopen_base,
            luaopen_table,
            luaopen_io,
            luaopen_string,
            luaopen_math,
            luaopen_debug,
#if LUA_VERSION_NUM > 500
	    luaopen_package,
#else
            luaopen_loadlib,
#endif
            luaopen_pop3server,
            luaopen_mlex,
            luaopen_stringhack,
            luaopen_session,
            luaopen_curl,
            luaopen_psock,
            luaopen_base64,
            luaopen_getdate,
            luaopen_regularexp,
            luaopen_lxp,
            luaopen_log,
            luaopen_crypto,
	    luaopen_lfs
        };

lua_State* luabox_genbox(unsigned long intial_stuff){
    lua_State* tmp = lua_open();
    MALLOC_CHECK(tmp);
    luabox_addtobox(tmp,intial_stuff);
    return tmp;
}

void luabox_addtobox(lua_State* box,unsigned long stuff){
    long int i;
    for ( i = 0 ; i < LUABOX_LAST ; i++) {
        int j = 1<<i;
        if (j & stuff) {
            opening_functions[i](box);
	    luay_emptystack(box);	
	}
    }
}

