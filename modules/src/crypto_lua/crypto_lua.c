/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://freepops.sf.net)                     *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	some of crypto lib to lua
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include "lua.h"
#include "luabind.h"
#include "lauxlib.h"

#include <stdlib.h>
#include <openssl/md5.h>
#include <openssl/hmac.h>
#include <openssl/evp.h>

#define CRYPTO_EVP_MD "crypto.evp_md.type"

static int lmd5(lua_State* L){
	MD5_CTX C;
	const char *data;
	size_t len;
	char md[MD5_DIGEST_LENGTH];
	
	data = luaL_checklstring(L,1,&len);

	MD5_Init(&C);
        MD5_Update(&C, (const void *)data,(unsigned long) len);
        MD5_Final(md, &C);

	lua_pushlstring(L,md,MD5_DIGEST_LENGTH);
	return 1;
}

static int lhmac(lua_State* L){
	HMAC_CTX C;
	const char *data;
	const char *key;
	size_t len;
	size_t klen;
	const EVP_MD *evp;
	char md[EVP_MAX_MD_SIZE];
	
	data = luaL_checklstring(L,1,&len);
	key = luaL_checklstring(L,2,&klen);
	evp = *(const EVP_MD **) luaL_checkudata(L,3,CRYPTO_EVP_MD);
        luaL_argcheck(L,evp != NULL,3,"crypto.EVP_* expected");
	
	//HMAC_CTX_init(&C);
	//printf("%p %p\n",evp,EVP_sha1);
	HMAC_Init/*_ex*/(&C,key,klen,((const EVP_MD *(*)(void))evp)());
	HMAC_Update(&C,(const void *)data,(unsigned long) len);
	len = EVP_MAX_MD_SIZE;
	HMAC_Final(&C,md,&len);
	HMAC_CTX_cleanup(&C);
		
	lua_pushlstring(L,md,len);
	return 1;
}


static const char *hex = "0123456789abcdef";

static int lbin2hex(lua_State* L){
	const char *data;
	size_t len;
	size_t i,o;
	char * enc;

	data = luaL_checklstring(L,1,&len);

	enc = calloc(len*2+1,sizeof(char));
	if (enc == NULL)
		L_error(L,"Out of memory");
	enc[len*2] = '\0';
	
	for(i = 0, o = 0 ; i < len ; i++, o+=2) {
		char cur = data[i];
		unsigned up,down;

		up = (cur & 0xF0) >> 4;
		down = cur & 0x0F;
		
		enc[o] = hex[up];
		enc[o+1] = hex[down];
	}

	lua_pushstring(L,enc);

	free(enc);
	
	return 1;
}

static int my_free(lua_State* L){/* nothing to do */ return 0;}

static const struct luaL_reg crypto_t [] = {
  {"md5",lmd5},
  {"hmac",lhmac},
  {"bin2hex",lbin2hex},
  {NULL,NULL}
};

static const struct L_Tuserdata crypto_evp [] = {
  {"EVP_md_null",EVP_md_null},
#ifndef OPENSSL_NO_MD2
  {"EVP_md2",EVP_md2},
#endif
#ifndef OPENSSL_NO_MD4
  {"EVP_md4",EVP_md4},
#endif
#ifndef OPENSSL_NO_MD5
  {"EVP_md5",EVP_md5},
#endif
#ifndef OPENSSL_NO_SHA
  {"EVP_sha",EVP_sha},
  {"EVP_sha1",EVP_sha1},
  {"EVP_dss",EVP_dss},
  {"EVP_dss1",EVP_dss1},
#endif
#ifndef OPENSSL_NO_MDC2
  {"EVP_mdc2",EVP_mdc2},
#endif
#ifndef OPENSSL_NO_RIPEMD
  {"EVP_ripemd160",EVP_ripemd160},
#endif
  {NULL,NULL}
};

int luaopen_crypto(lua_State* L){
	
	luaL_newmetatable(L,CRYPTO_EVP_MD);
	
	lua_pushstring(L,"__gc");
	lua_pushcfunction(L,my_free);
	lua_settable(L,-3);

	luaL_openlib(L,"crypto",crypto_t,0);

	L_openTconst(L,crypto_evp,CRYPTO_EVP_MD);

	return 2;
}
