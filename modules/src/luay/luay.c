#include <stdio.h>
#include <math.h>
#include <string.h>

#include "lua.h"
#include "luay.h"

#define LINE_PREFIX "LUA: "

void luay_printstack(lua_State* s)	
{
int i;
fprintf(stderr,"%slua stack image:\n",LINE_PREFIX);
for(i=lua_gettop(s) ; i > 0 ; i-- )
	{
	fprintf(stderr,"%sstack(%2d) : %s: ",LINE_PREFIX,i,
		lua_typename(s,lua_type(s,i)));
	if(lua_isstring(s,i))
		fprintf(stderr," \"%s\"\n",lua_tostring(s,i));
	else if (lua_isnumber(s,i))
		fprintf(stderr," %5.3f\n",lua_tonumber(s,i));
	else if (lua_isboolean(s,i))
		fprintf(stderr," %s\n",lua_toboolean(s,i)==0?"true":"false");
	else if (lua_isnil(s,i))
		fprintf(stderr," nil\n");
	else
		fprintf(stderr," ??\n");
	}
fprintf(stderr,"%sstack( 0) : --bottom--\n\n",LINE_PREFIX);
}


/*! \brief used in lualp_call
 *
 */ 
#define luay_pusharg(s,x,vargs) {\
switch(x)\
	{\
	\
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
	case 'd':\
		{\
		int* d = va_arg(vargs,int*);\
		lua_Number n;\
		if(!lua_isnumber(s,1))\
			goto error;\
		n = lua_tonumber(s,1);\
		*d = (int)floor(n);\
		}\
	break;\
	case 'f':\
		{\
		double* d = va_arg(vargs,double*);\
		if(!lua_isnumber(s,1))\
			goto error;\
		*d =  lua_tonumber(s,1);\
		}\
	break;\
	case 's':\
		{\
		char** st = va_arg(vargs,char **);\
		if(!lua_isstring(s,1))\
			goto error;\
		*st =  strdup(lua_tostring(s,1));\
		}\
	break;\
	case 'S':\
		{\
		char** st = va_arg(vargs,char **);\
		if(!lua_isstring(s,1))\
			goto error;\
		*st =  (char*)lua_tostring(s,1);\
		}\
	break;\
	case 'p':\
		{\
		void **p = va_arg(vargs,void **);\
		if(!lua_islightuserdata(s,1))\
			goto error;\
		*p = lua_touserdata(s,1);\
		}\
	break;\
	default:\
		goto error;\
	break;\
	}\
lua_remove(s,1);\
}\

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
int i,nret,rc;
char* c;
va_list vargs;

// put the function on the stack
lua_pushstring(s,"_G");
lua_gettable(s,LUA_GLOBALSINDEX);
c = (char*)funcname;
while(c != NULL)
	{
	i = find_member_len(c);
	if(i > 0)
		{
		lua_pushlstring(s,c,i);
		
		lua_rawget(s,1);
		
		lua_remove(s,1);
		
		c = find_next_member(c);
		}
	}

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
rc = lua_pcall(s,i,nret,0);
if(rc != 0)
	{
	luay_printstack(s);
	return 1;
	}

// pop returns
if(nret > 0)
	for(i++;args[i] != '\0';i++)
		{
		luay_poparg(s,args[i],vargs);
		}

// empty the stack (needed?)
luay_emptystack(s);

va_end(vargs);
return 0;

error:
	fprintf(stderr,
		"%s: %d: ERROR{args='%s' funcname='%s' i=%d args[i]=%c}\n",
		__FILE__,__LINE__,args,funcname,i,args[i]);
	luay_printstack(s);
	return 1;
}

