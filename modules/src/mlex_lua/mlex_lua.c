/*
** Lua binding: mlex_lua
** Generated automatically by tolua++-1.0.2 on Sun Mar 14 14:38:36 2004.

HACKED BY HAND!!!!!


*/

#ifndef __cplusplus
#include "stdlib.h"
#endif
#include "string.h"

#include "tolua++.h"

/* Exported function */
TOLUA_API int tolua_mlex_lua_open (lua_State* tolua_S);

#include "list.h"
#include "mlex.h"

/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
}

/* function: mlmatch */
static int tolua_mlex_lua_mlex_match00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
 !tolua_isstring(tolua_S,1,0,&tolua_err) ||
 !tolua_isstring(tolua_S,2,0,&tolua_err) ||
 !tolua_isstring(tolua_S,3,0,&tolua_err) ||
 !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
 goto tolua_lerror;
 else
#endif
 {
  char* data = ((char*)  tolua_tostring(tolua_S,1,0));
  char* exp = ((char*)  tolua_tostring(tolua_S,2,0));
  char* ret = ((char*)  tolua_tostring(tolua_S,3,0));
 {
  void* tolua_ret = (void*)  mlmatch(data,exp,ret);
 tolua_pushuserdata(tolua_S,(void*)tolua_ret);
 }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'match'.",&tolua_err);
 return 0;
#endif
}

/* function: mlmatch_print_results */
static int tolua_mlex_lua_mlex_print00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
 !tolua_isuserdata(tolua_S,1,0,&tolua_err) ||
 !tolua_isstring(tolua_S,2,0,&tolua_err) ||
 !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
 goto tolua_lerror;
 else
#endif
 {
  void* res = ((void*)  tolua_touserdata(tolua_S,1,0));
  char* str = ((char*)  tolua_tostring(tolua_S,2,0));
 {
  mlmatch_print_results(res,str);
 }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'print'.",&tolua_err);
 return 0;
#endif
}

/* function: mlmatch_free_results */
static int tolua_mlex_lua_mlex_free00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
 !tolua_isuserdata(tolua_S,1,0,&tolua_err) ||
 !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
 goto tolua_lerror;
 else
#endif
 {
  void* res = ((void*)  tolua_touserdata(tolua_S,1,0));
 {
  mlmatch_free_results(res);
 }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'free'.",&tolua_err);
 return 0;
#endif
}

/* function: mlmatch_get_result */
static int tolua_mlex_lua_mlex_get00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
 !tolua_isnumber(tolua_S,1,0,&tolua_err) ||
 !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
 !tolua_isuserdata(tolua_S,3,0,&tolua_err) ||
 !tolua_isstring(tolua_S,4,0,&tolua_err) ||
 !tolua_isnoobj(tolua_S,5,&tolua_err)
 )
 goto tolua_lerror;
 else
#endif
 {
  int x = ((int)  tolua_tonumber(tolua_S,1,0));
  int y = ((int)  tolua_tonumber(tolua_S,2,0));
  void* res = ((void*)  tolua_touserdata(tolua_S,3,0));
  char* s = ((char*)  tolua_tostring(tolua_S,4,0));
 {
  char* tolua_ret = (char*)  mlmatch_get_result(x,y,res,s);
 tolua_pushstring(tolua_S,(const char*)tolua_ret);
 //XXX HACKED HERE XXX
 free((char*)tolua_ret);
 //XXX HACKED HERE XXX
 }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'get'.",&tolua_err);
 return 0;
#endif
}

/* function: list_len */
static int tolua_mlex_lua_mlex_count00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
 !tolua_isuserdata(tolua_S,1,0,&tolua_err) ||
 !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
 goto tolua_lerror;
 else
#endif
 {
  void* res = ((void*)  tolua_touserdata(tolua_S,1,0));
 {
  int tolua_ret = (int)  list_len(res);
 tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
 }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'count'.",&tolua_err);
 return 0;
#endif
}

/* Open function */
TOLUA_API int tolua_mlex_lua_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
 tolua_module(tolua_S,"mlex",0);
 tolua_beginmodule(tolua_S,"mlex");
 tolua_function(tolua_S,"match",tolua_mlex_lua_mlex_match00);
 tolua_function(tolua_S,"print",tolua_mlex_lua_mlex_print00);
 tolua_function(tolua_S,"free",tolua_mlex_lua_mlex_free00);
 tolua_function(tolua_S,"get",tolua_mlex_lua_mlex_get00);
 tolua_function(tolua_S,"count",tolua_mlex_lua_mlex_count00);
 tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}
