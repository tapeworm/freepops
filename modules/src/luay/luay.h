/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   luay.h
  * \brief  more handy lua_call wrapper
  * 
  * \author Name <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/
#ifndef _LUALP_H_
#define _LUALP_H_

/*! \brief calls a lua function and returns values
 *  Calls a lua function in protected mode and returns multiple arguments.
 *  \param args is a formt string. It tells both passed arguments and 
 *  	expected arguments. The '|' is used as a separator for in/out 
 *  	parameters. Type specifyers are d for int, s for char*, p for
 *  	void*(lightuserdata), f for double, b for bool, v for lua value
 *  	(as stack position, as output the value is left as is).
 *  	An example of format string is
 *  	"spf|dp" says that the function takes a string, a userdata and a 
 *  	double(lua_Number) and return an integer(trucated lua_Number) and 
 *  	a lightuserdata. With 's' string received are strdup()ed, since
 *  	the pointer to the LUA data may become a dandling reference due to a 
 *  	garbage collector call. If you are sure the LUA string will not be 
 *  	collected you can use 'S' instead. 
 *  \param funcname the function name
 *  \param ... arguments are passed as described int the args parameter,
 *  	remember that returns values must be of type pointer-to. For 
 *  	example a function "|dfsp" must be called<BR>
 *  	<TT>
 *  	int	r1;
 *  	double	r2;
 *  	char*	r3;
 *  	void*	r4;
 *  	lualp_call(S,"|dfsp","functionname",&r1,&r2,&r3,&r4);
 *  	</TT>
 *
 */ 
int luay_call(lua_State* s,const char *args,const char *funcname,...);

/*!
 * \brief as before but the input is a char* array.
 *
 * The output is arbitrary as described in args that should omit every input.
 *
 */ 
int luay_callv(lua_State* s,const char *args,const char *funcname,
		char**argv, int len, ...);

/*! \brief pops all the stak's elements
 *
 */ 
#define luay_emptystack(s) {\
	while(lua_gettop(s) != 0)\
	lua_pop(s,1);\
	}

/*! \brief prints the stack of the luaVM
 */ 
void luay_printstack(lua_State* s);

/*! \brief prints the calling trace of the luaVM
 * Internally used as the error function for lua_pcall
 */ 
int luay_printtrace(lua_State* s);

#endif
