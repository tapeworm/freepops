#include <lua.h>
#include <lauxlib.h>

#include "popserver.h"
#include "popstate.h"

#include "luabind.h"

#include "compat-5.1.h"

/*******************************************************************************
 * set_popstate_nummesg
 *
 */ 
static int L_set_popstate_nummesg(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int n = luaL_checkint(L,2);
 L_checknarg(L,2,"set_popstate_nummesg wants 2 args (p,number)");
 set_popstate_nummesg(p,n);
 return 0;
}

/*******************************************************************************
 * set_popstate_password
 *
 */ 
static int L_set_popstate_password(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 const char* s = luaL_checkstring(L,2);
 L_checknarg(L,2,"set_popstate_password wants 2 args (p,string)");
 set_popstate_password(p,s);
 return 0;
}


/*******************************************************************************
 * set_popstate_username
 *
 */ 
static int L_set_popstate_username(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 const char* s = luaL_checkstring(L,2);
 L_checknarg(L,2,"set_popstate_username wants 2 args (p,string)");
 set_popstate_username(p,s);
 return 0;
}


/*******************************************************************************
 * get_popstate_password
 *
 */ 
static int L_get_popstate_password(lua_State* L) {
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 const char *s;
 L_checknarg(L,1,"get_popstate_password wants 1 arg (p)");
 s = get_popstate_password(p);
 lua_pushstring(L,s);
 return 1;
}


/*******************************************************************************
 * get_popstate_username
 *
 */ 
static int L_get_popstate_username(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 const char *s;
 L_checknarg(L,1,"get_popstate_username wants 1 arg (p)");
 s = get_popstate_password(p);
 lua_pushstring(L,s);
 return 1;
}


/*******************************************************************************
 * get_popstate_nummesg
 *
 */ 
static int L_get_popstate_nummesg(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int n;
 L_checknarg(L,1,"get_popstate_nummesg wants 1 arg (p)");
 n = get_popstate_nummesg(p);
 lua_pushnumber(L,(double)n);
 return 1;
}


/*******************************************************************************
 * get_popstate_boxsize
 *
 */ 
static int L_get_popstate_boxsize(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int n;
 L_checknarg(L,1,"get_popstate_boxsize wants 1 arg (p)");
 n = get_popstate_boxsize(p);
 lua_pushnumber(L,(double)n);
 return 1;
}


/*******************************************************************************
 * set_popstate_boxsize
 *
 */ 
static int L_set_popstate_boxsize(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int n = luaL_checkint(L,2);
 L_checknarg(L,2,"set_popstate_boxsize wants 2 args (p,number)");
 set_popstate_boxsize(p,n);
 return 0;
}


/*******************************************************************************
 * popserver_callback
 *
 */ 
static int L_popserver_callback(lua_State* L){
 const char* s = luaL_checkstring(L,1);
 void * d = L_checkludata(L,2);
 int n;
 L_checknarg(L,2,"popserver_callback wants 2 args (string,data)");
 n = popserver_callback(s,d);
 lua_pushnumber(L,(double)n);
 return 1;
}

/*******************************************************************************
 * set_mailmessage_uidl
 *
 */ 
static int L_set_mailmessage_uidl(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int num = luaL_checkint(L,2) - 1;
 const char* s = luaL_checkstring(L,3);
 struct mail_msg_t* m=NULL;
 
 L_checknarg(L,3,"set_mailmessage_uidl wants 3 args (p,number,string)");
 m = get_popstate_mailmessage(p,num);
 if ( m == NULL ) 
 	L_error(L,"Invalid message number %d",num);
  
 set_mailmessage_uidl(m,s);
 	
 return 0;
}

/*******************************************************************************
 * set_mailmessage_size
 *
 */ 
static int L_set_mailmessage_size(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int num = luaL_checkint(L,2) - 1;
 int size = luaL_checkint(L,3);
 struct mail_msg_t* m=NULL;
 
 L_checknarg(L,3,"set_mailmessage_size wants 3 args (p,number,number)");
 m = get_popstate_mailmessage(p,num);
 if ( m == NULL ) 
 	L_error(L,"Invalid message number %d",num);
  
 set_mailmessage_size(m,size);
 
 return 0;
}

/*******************************************************************************
 * set_mailmessage_flag
 *
 */ 
static int L_set_mailmessage_flag(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int num = luaL_checkint(L,2) - 1;
 int flag = luaL_checkint(L,3);
 struct mail_msg_t* m=NULL;
  
 L_checknarg(L,3,"set_mailmessage_flag wants 3 args (p,number,number)");
 m = get_popstate_mailmessage(p,num);
 if ( m == NULL ) 
 	L_error(L,"Invalid message number %d",num);
 
 set_mailmessage_flag(m,flag);
 
 return 0;
}

/*******************************************************************************
 * unset_mailmessage_flag
 *
 */ 
static int L_unset_mailmessage_flag(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int num = luaL_checkint(L,2) - 1;
 int flag = luaL_checkint(L,3);
 struct mail_msg_t* m=NULL;
  
 L_checknarg(L,3,"unset_mailmessage_flag wants 3 args (p,number,number)");
 m = get_popstate_mailmessage(p,num);
 if ( m == NULL ) 
  	L_error(L,"Invalid message number %d",num);
 
 unset_mailmessage_flag(m,flag);
 
 return 0;
}

/*******************************************************************************
 * get_mailmessage_size
 *
 */ 
static int L_get_mailmessage_size(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int num = luaL_checkint(L,2) - 1;
 struct mail_msg_t* m=NULL;
 int size = 0;
  	
 L_checknarg(L,2,"get_mailmessage_size wants 2 args (p,number)");
 m = get_popstate_mailmessage(p,num);
 if ( m == NULL ) 
 	L_error(L,"Invalid message number %d",num);
 
 size = get_mailmessage_size(m);
  
 lua_pushnumber(L,size);
  
 return 1;
}

/*******************************************************************************
 * get_mailmessage_uidl
 *
 */ 
static int L_get_mailmessage_uidl(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int num = luaL_checkint(L,2) - 1;
 struct mail_msg_t* m=NULL;
 const char * uidl;
 
 L_checknarg(L,2,"get_mailmessage_uidl wants 2 args (p,number)");
 m = get_popstate_mailmessage(p,num);
 if ( m == NULL ) 
 	L_error(L,"Invalid message number %d",num);
 
 uidl = get_mailmessage_uidl(m);
 
 lua_pushstring(L,uidl);
 		
 return 1;
}

/*******************************************************************************
 * get_mailmessage_flag
 *
 */ 
static int L_get_mailmessage_flag(lua_State* L){
 struct popstate_t * p = (struct popstate_t *)L_checkludata(L,1);
 int num = luaL_checkint(L,2) - 1;
 int flag = luaL_checkint(L,3);
 struct mail_msg_t* m=NULL;
 int rc;

 L_checknarg(L,3,"get_mailmessage_flag wants 3 args (p,number,number)");
 m = get_popstate_mailmessage(p,num);
 if ( m == NULL ) 
 	L_error(L,"Invalid message number %d",num);
  
 rc = get_mailmessage_flag(m,flag);
 
 lua_pushboolean(L,rc);
 
 return 1;
}
	
/*******************************************************************************
 * the functions
 *
 */ 
static const struct luaL_reg pop3server_m [] = {
  {"set_popstate_nummesg",L_set_popstate_nummesg},
  {"set_popstate_password",L_set_popstate_password},
  {"set_popstate_username",L_set_popstate_username},
  {"get_popstate_password",L_get_popstate_password},
  {"get_popstate_username",L_get_popstate_username},
  {"get_popstate_nummesg",L_get_popstate_nummesg},
  {"get_popstate_boxsize",L_get_popstate_boxsize},
  {"set_popstate_boxsize",L_set_popstate_boxsize},
  {"popserver_callback",L_popserver_callback},
  {"set_mailmessage_uidl",L_set_mailmessage_uidl},
  {"set_mailmessage_size",L_set_mailmessage_size},
  {"set_mailmessage_flag",L_set_mailmessage_flag},
  {"unset_mailmessage_flag",L_unset_mailmessage_flag},
  {"get_mailmessage_size",L_get_mailmessage_size},
  {"get_mailmessage_uidl",L_get_mailmessage_uidl},
  {"get_mailmessage_flag",L_get_mailmessage_flag},
  {NULL,NULL}
};

/*******************************************************************************
 * ERRORS and FLAGS
 *
 */ 
static const struct L_const pop3server_c [] = {
  {"POPSERVER_ERR_OK",POPSERVER_ERR_OK},
  {"POPSERVER_ERR_SYNTAX",POPSERVER_ERR_SYNTAX},
  {"POPSERVER_ERR_NETWORK",POPSERVER_ERR_NETWORK},
  {"POPSERVER_ERR_AUTH",POPSERVER_ERR_AUTH},
  {"POPSERVER_ERR_INTERNAL",POPSERVER_ERR_INTERNAL},	
  {"POPSERVER_ERR_NOMSG",POPSERVER_ERR_NOMSG},
  {"POPSERVER_ERR_LOCKED",POPSERVER_ERR_LOCKED},
  {"POPSERVER_ERR_EOF",POPSERVER_ERR_EOF},
  {"POPSERVER_ERR_TOOFAST",POPSERVER_ERR_TOOFAST},	
  {"POPSERVER_ERR_UNKNOWN",POPSERVER_ERR_UNKNOWN},	
  {"MAILMESSAGE_DELETE",MAILMESSAGE_DELETE},
  {NULL,0}
};

/*******************************************************************************
 * to open the stuff
 *
 */ 
int luaopen_pop3server(lua_State* L) {
 luaL_openlib(L,"pop3server",pop3server_m,0);
 L_openconst(L,pop3server_c);
 
 return 1;
}

