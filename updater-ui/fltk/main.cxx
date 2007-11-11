/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	updater_fltk lua module
 * Notes:
 *	
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <stdlib.h>
#include <lua.hpp>

#include "updater.h"
#include "linker.h"

static int updater_run(lua_State* l){
	Fl_Double_Window* win = make_main_window();
	updater_init(l);
#ifdef WIN32
	char* argv[] = {"freepops"};
#else
	const char* argv[] = {"freepops"};
#endif
	win->show(1, argv);
	lua_pushnumber(l,Fl::run());
	return 1;
}

static struct luaL_Reg updater_reg[] = {
	{"run",updater_run},
	{NULL,NULL}
};


extern "C" int luaopen_updater_fltk(lua_State* l){
	luaL_register(l,"updater_fltk",updater_reg);
	return 1;
}

