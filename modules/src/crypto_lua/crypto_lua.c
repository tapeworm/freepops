#include "lua.h"
#include "luabind.h"
#include "lauxlib.h"

#include <stdlib.h>
#include <openssl/md5.h>

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

static const struct luaL_reg crypto_t [] = {
  {"md5",lmd5},
  {"bin2hex",lbin2hex},
  {NULL,NULL}
};

int luaopen_crypto(lua_State* L){
	
	luaL_openlib(L,"crypto",crypto_t,0);

	return 1;
}
