/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
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
#define CRYPTO_ALGO_MD "crypto.ALGO_md.type"

#define CRYPTO_GCRYPT	1
#define CRYPTO_OPENSSL	2
#ifndef CRYPTO_IMPLEMENTATION
	#define CRYPTO_IMPLEMENTATION CRYPTO_OPENSSL
#endif

#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	#include <openssl/opensslconf.h>
	#include <openssl/md5.h>
	#include <openssl/hmac.h>
	#include <openssl/evp.h>
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	#include <gcrypt.h>
#else
	#error "CRYPTO_IMPLEMENTATION not supported"
#endif

// =================== MD5 ==================
static int lmd5(lua_State* L){
	size_t len;
	const char *data = luaL_checklstring(L,1,&len);
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	size_t digest_len = MD5_DIGEST_LENGTH;
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	size_t digest_len = gcry_md_get_algo_dlen(GCRY_MD_MD5);
#endif
	char md[digest_len];
	
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	MD5_CTX C;
	MD5_Init(&C);
        MD5_Update(&C, (const void *)data,(unsigned long) len);
        MD5_Final((unsigned char *)md, &C);
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	gcry_md_hash_buffer(GCRY_MD_MD5,md,data,len);
#endif
	
	lua_pushlstring(L,md,digest_len);
	return 1;
}

// ============================ generic HMAC ==============================

static int lhmac(lua_State* L){
	const char *data;
	const char *key;
	size_t len_sizet;
	size_t klen;
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	unsigned int len_uint;
	HMAC_CTX C;
	const EVP_MD *evp;
	char md[EVP_MAX_MD_SIZE];
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	int algo;
	gcry_md_hd_t hd;
	unsigned char * tmp;
#endif
	
	data = luaL_checklstring(L,1,&len_sizet);
	key = luaL_checklstring(L,2,&klen);
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	evp = *(const EVP_MD **) luaL_checkudata(L,3,CRYPTO_ALGO_MD);
        luaL_argcheck(L,evp != NULL,3,"crypto.ALGO_* expected");
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	algo = (int)luaL_checkudata(L,3,CRYPTO_ALGO_MD);
	luaL_argcheck(L,algo != GCRY_MD_NONE,3,"crypto.ALGO_* expected");
#endif
	
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	len_uint = len_sizet;
	HMAC_Init(&C,key,klen,((const EVP_MD *(*)(void))evp)());
	HMAC_Update(&C,(const void *)data,len_uint);
	len_uint = EVP_MAX_MD_SIZE;
	HMAC_Final(&C,(unsigned char *)md,&len_uint);
	HMAC_cleanup(&C);
	len_sizet = len_uint;
	lua_pushlstring(L,md,len_sizet);
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	gcry_md_open(&hd,algo,GCRY_MD_FLAG_HMAC);
	gcry_md_setkey(hd,key,klen);
	gcry_md_write(hd,data,len_sizet);
	gcry_md_final(hd);
	tmp = gcry_md_read(hd,algo);
	lua_pushlstring(L,(char*)tmp,gcry_md_get_algo_dlen(algo));
	gcry_md_close(hd);
#endif
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

static const struct L_Tuserdata crypto_ALGO [] = {
// ======= NULL ====
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	  {"ALGO_md_null",EVP_md_null},
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	  {"ALGO_md_null", (void*)GCRY_MD_NONE},
#endif
// ====== MD* =====
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	#ifndef OPENSSL_NO_MD2
	  {"ALGO_md2",EVP_md2},
	#endif
	#ifndef OPENSSL_NO_MD4
	  {"ALGO_md4",EVP_md4},
	#endif
	#ifndef OPENSSL_NO_MD5
	  {"ALGO_md5",EVP_md5},
	#endif
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	  {"ALGO_md2", (void*)GCRY_MD_MD2},
	  {"ALGO_md4", (void*)GCRY_MD_MD4},
	  {"ALGO_md5", (void*)GCRY_MD_MD5},
#endif
// ====== SHA* =====
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	#ifndef OPENSSL_NO_SHA
	  {"ALGO_sha",EVP_sha},
	  {"ALGO_sha1",EVP_sha1},
	  {"ALGO_dss",EVP_dss},
	  {"ALGO_dss1",EVP_dss1},
	#endif
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	  {"ALGO_sha1", (void*)GCRY_MD_SHA1},
	  {"ALGO_sha256", (void*)GCRY_MD_SHA256},
	  {"ALGO_sha384", (void*)GCRY_MD_SHA384},
	  {"ALGO_sha512", (void*)GCRY_MD_SHA512},
#endif  
// ====== MDC2 & RIPE160 =====
#if CRYPTO_IMPLEMENTATION == CRYPTO_OPENSSL
	#if defined(HEADER_MDC2_H)
	#ifndef OPENSSL_NO_MDC2
	  {"ALGO_mdc2",EVP_mdc2},
	#endif
	#endif
	#ifndef OPENSSL_NO_RIPEMD
	  {"ALGO_ripemd160",EVP_ripemd160},
	#endif
#elif CRYPTO_IMPLEMENTATION == CRYPTO_GCRYPT
	  {"ALGO_ripemd160", (void*)GCRY_MD_RMD160},
#endif  
  {NULL,NULL}
};

int luaopen_crypto(lua_State* L){
	
	luaL_newmetatable(L,CRYPTO_ALGO_MD);
	
	lua_pushstring(L,"__gc");
	lua_pushcfunction(L,my_free);
	lua_settable(L,-3);

	luaL_openlib(L,"crypto",crypto_t,0);

	L_openTconst(L,crypto_ALGO,CRYPTO_ALGO_MD);

	return 2;
}
