/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	lua_call wrapper
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/
#include <stdio.h>
#include <math.h>
#include <string.h>

#include "lua.h"
#include "luay.h"

#define LINE_PREFIX "LUAY: "

// uncomment for debugging C calls of LUA functions
// #define PRINT_FUNCTIONS

int luay_printtrace(lua_State* s)
{
lua_Debug d;
int i;

memset(&d,0,sizeof(lua_Debug));

fprintf(stderr,"\n%slua error message:\n",LINE_PREFIX);
if(lua_isstring(s,lua_gettop(s)))
	fprintf(stderr,"%s   %s\n\n",LINE_PREFIX,lua_tostring(s,lua_gettop(s)));
fprintf(stderr,"%slua stack traceback:\n",LINE_PREFIX);
for (i = 1 ; lua_getstack(s,i,&d) == 1 ; i++)
	{
	if(lua_getinfo(s,"Snl",&d) == 0)
		fprintf(stderr,"%sUnable to get infos for %d\n",LINE_PREFIX,i);
	
	fprintf(stderr,"%s   %s: %s: %d (%s %s)\n",LINE_PREFIX,
		d.short_src,d.name,d.currentline,d.what,d.namewhat);

	}
fprintf(stderr,"\n");
fflush(stderr);

return LUA_ERRRUN;
}

void luay_printstack(lua_State* s)	
{
int i;

fprintf(stderr,"%slua stack image:\n",LINE_PREFIX);
for(i=lua_gettop(s) ; i > 0 ; i-- )
	{
	fprintf(stderr,"%sstack(%2d) : %s: ",LINE_PREFIX,i,
		lua_typename(s,lua_type(s,i)));
	switch(lua_type(s,i)){
		case LUA_TSTRING:
			fprintf(stderr," \"%s\"\n",lua_tostring(s,i));
		break;
		case LUA_TNUMBER:
			fprintf(stderr," %5.3f\n",lua_tonumber(s,i));
		break;
		case LUA_TBOOLEAN:
			fprintf(stderr," %s\n",
				lua_toboolean(s,i)==0?"false":"true");
		break;
		case LUA_TNIL:
			fprintf(stderr," nil\n");
		break;
		default:
			fprintf(stderr," ??\n");
		break;
	}
	}
fprintf(stderr,"%sstack( 0) : --bottom--\n\n",LINE_PREFIX);
fflush(stderr);
}


#define VARDECL \
	int i,nret,rc,base;\
	char* c;\
	va_list vargs;

/*! \brief used in lualp_call
 *
 */ 
#define luay_pusharg(s,x,vargs) {\
switch(x)\
	{\
	\
	case 'b':\
		{\
		int d = va_arg(vargs,int);\
		lua_pushboolean(s,(lua_Number)d);\
		}\
	break;\
	case 'd':\
		{\
		int d = va_arg(vargs,int);\
		lua_pushnumber(s,(lua_Number)d);\
		}\
	break;\
	case 'f':\
		{\
		double d = va_arg(vargs,double);\
		lua_pushnumber(s,(lua_Number)d);\
		}\
	break;\
	case 'S':\
	case 's':\
		{\
		const char *st = va_arg(vargs,const char *);\
		lua_pushstring(s,st);\
		}\
	break;\
	case 'p':\
		{\
		void* p = va_arg(vargs,void *);\
		lua_pushlightuserdata(s,p);\
		}\
	break;\
	default:\
		goto error;\
	break;\
	\
	}\
}

/*! \brief used in lualp_call
 *
 */
#define luay_poparg(s,x,vargs) {\
switch(x)\
	{\
	case 'b':\
		{\
		int* d = va_arg(vargs,int*);\
		*d = (int)lua_toboolean(s,base+1);\
		}\
	break;\
	case 'd':\
		{\
		int* d = va_arg(vargs,int*);\
		lua_Number n;\
		if(!lua_isnumber(s,base+1))\
			goto error;\
		n = lua_tonumber(s,base+1);\
		*d = (int)floor(n);\
		}\
	break;\
	case 'f':\
		{\
		double* d = va_arg(vargs,double*);\
		if(!lua_isnumber(s,base+1))\
			goto error;\
		*d =  lua_tonumber(s,base+1);\
		}\
	break;\
	case 's':\
		{\
		char** st = va_arg(vargs,char **);\
		if(!lua_isstring(s,base+1))\
			goto error;\
		*st =  strdup(lua_tostring(s,base+1));\
		}\
	break;\
	case 'S':\
		{\
		char** st = va_arg(vargs,char **);\
		if(!lua_isstring(s,base+1))\
			goto error;\
		*st =  (char*)lua_tostring(s,base+1);\
		}\
	break;\
	case 'p':\
		{\
		void **p = va_arg(vargs,void **);\
		if(!lua_islightuserdata(s,base+1))\
			goto error;\
		*p = lua_touserdata(s,base+1);\
		}\
	break;\
	default:\
		goto error;\
	break;\
	}\
lua_remove(s,base+1);\
}\

#define PREAMBLE \
	lua_pushcfunction(s,luay_printtrace);\
	base = lua_gettop(s);\
	lua_pushstring(s,"_G");\
	lua_gettable(s,LUA_GLOBALSINDEX);\
	c = (char*)funcname;\
	while(c != NULL)\
		{\
		i = find_member_len(c);\
		if(i > 0)\
			{\
			lua_pushlstring(s,c,i);\
			lua_rawget(s,base+1);\
			lua_remove(s,base+1);\
			c = find_next_member(c);\
			}\
		}

#define ERROR_HANDLER \
	error:\
	fprintf(stderr,\
		"%s: %d: ERROR: args='%s' funcname='%s' i='%d' args[i]='%c'\n",\
		__FILE__,__LINE__,args,funcname,i,args[i]);\
	fflush(stderr);\
	luay_printstack(s);\
	return 1;

static char * find_next_member(char* s)
{
//find a .
while(*s != '\0' && *s != '.')
	s++;
if(*s != '\0')
	return s+1;

return NULL;
}

static int find_member_len(char* s)
{
int i=0;
//find a .
while(*s != '\0' && *s != '.')
	{
	s++;
	i++;
	}

return i;
}

int luay_call(lua_State* s,const char *args,const char *funcname,...)
{
VARDECL
PREAMBLE

// put parameters
va_start(vargs,funcname);
for(i = 0 ; args[i] != '\0' && args[i] != '|' ; i++)
	{
	luay_pusharg(s,args[i],vargs);
	}

// count return values
if( args[i] == '|')
	nret = strlen(&args[i]) -1;
else
	nret = 0;

//call the function
#ifdef PRINT_FUNCTIONS
	fprintf(stderr,"%scalling: %s\n", LINE_PREFIX, funcname);
	luay_printstack(s);
#endif
rc = lua_pcall(s,i,nret,base);
if(rc != 0)
	{
	return 1;
	}

// pop returns
if(nret > 0)
	for(i++;args[i] != '\0';i++)
		{
		if (args[i] != '.')
			luay_poparg(s,args[i],vargs);
		}

// empty the stack (needed for the c function)
lua_remove(s,base);

va_end(vargs);
return 0;

ERROR_HANDLER
}


int luay_callv(lua_State* s,const char *args,const char *funcname,
		char**argv, int len, ...)
{
VARDECL

if(args[0] != '|') 
	{
	fprintf(stderr,"luay_callv input args must contain no input\n");
	return 1;
	}

PREAMBLE

// put parameters
lua_newtable(s);
for(i = 0 ; i<len ; i++)
	{
	lua_pushstring(s,argv[i]);
	lua_rawseti(s,-2,i+1);
	}

// count return values
nret = strlen(args) -1; // -1 is for '|'

//call the function
#ifdef PRINT_FUNCTIONS
	fprintf(stderr,"%scalling: %s\n", LINE_PREFIX, funcname);
	luay_printstack(s);
#endif
rc = lua_pcall(s,1,nret,base);
if(rc != 0)
	{
	return 1;
	}

// pop returns
va_start(vargs,len);
if(nret > 0)
	for(i=1;args[i] != '\0';i++)
		{
		luay_poparg(s,args[i],vargs);
		}

// empty the stack (needed for the c function)
lua_remove(s,base);

va_end(vargs);
return 0;

ERROR_HANDLER
}
