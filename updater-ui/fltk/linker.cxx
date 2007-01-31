/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	bridge to freepops/lua
 * Notes:
 *	
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <lua.hpp>
#include <libintl.h>
#include <stdlib.h>

extern "C" {
#include "luay.h"
#include "log.h"
#define LOG_ZONE "linker"
}

#include <Fl/fl_ask.H>

#include "updater.h"

#define val(name,data) data;int name = lua_gettop(L)
#define _(x) gettext(x)

static lua_State* L;

void updater_init(lua_State*l){
	L=l;
	luay_call(L,"s|","require","updater_common");
	luay_call(L,"s|","require","updater_php");
	luaL_Buffer B;
	luaL_buffinit(L,&B);
	luaL_addstring(&B,"<html><head><title>");
	luaL_addstring(&B,_("Welcome"));
	luaL_addstring(&B,"</title></head><body><h1>");
	luaL_addstring(&B,_("Welcome to the FreePOPs updater!"));
	luaL_addstring(&B,"</h1><p>");
	luaL_addstring(&B,_(" This wizard will guide you trough the few simple steps to get your FreePOPs modules updated."));
	luaL_addstring(&B,"</p><p>");
	luaL_addstring(&B,_("Click <i>Next</i> to move to the first step."));
	luaL_addstring(&B,"</p></body></html>");
	luaL_pushresult(&B);
	updater_hlp_page_html->value(lua_tostring(L,-1));
	lua_pop(L,1);
}

static int upgradable;
static int metadata;
static int modules;
static int browser;

// used if failed fetching the plugin metadata
static void push_fake_metadata(lua_State* L, const char* string){
	val(TAB,lua_newtable(L));
	lua_pushstring(L,"Unknown");
	lua_setfield(L,TAB,"version");
	lua_pushstring(L,"Unknown");
	lua_setfield(L,TAB,"local_version");
	lua_pushstring(L,string);
	lua_setfield(L,TAB,"why_cannot_update");
	lua_pushboolean(L,false);
	lua_setfield(L,TAB,"should_update");
	lua_pushboolean(L,false);
	lua_setfield(L,TAB,"can_update");
}

// leaves on the stack 3 tables and a browser object
void updater_download_metadata(){
	lua_pop(L,lua_gettop(L));
	updater_prg_page_download->value(0);
	updater_prg_page_download->copy_label(_("Downloading: plugin list"));
	Fl::check();
	// the browser object
	val(BROWSER, luay_call(L,"|","browser.new"));
	// the table to contain all metadata
	val(METADATA,lua_newtable(L));
	// the table to contain al modules that can be updated
	val(UPGRADABLE,lua_newtable(L));
	// te table that lists all plugin names
	int rc = luay_call(L,"s|vv","updater_php.list_modules","official");
	if (rc != 0 || lua_isnil(L,-2)) {
		fl_alert(_("Unable to download the module list:\n%s"),
			lua_tostring(L,-1));
		updater_failure();
		return;
	}
	lua_pop(L,1); // the erorr message
	int MODULES = lua_gettop(L);

	size_t size = lua_objlen(L,-1);
	size_t i = 0;
	lua_pushnil(L);
	while (lua_next(L,-2) != 0) {
		// change progressbar
		updater_prg_page_download->value(i*100/size);
		// set the lable
		lua_pushfstring(L,_("Downloading: %s"),lua_tostring(L,-1));
		updater_prg_page_download->copy_label(lua_tostring(L,-1));
		lua_pop(L,1);
		// redraw
		Fl::check(); 
		int rc = luay_call(L,"ssv|vv","updater_php.fetch_module_metadata",
			lua_tostring(L,-1),"official",BROWSER);
		if (rc != 0 || lua_isnil(L,-2)) {
			push_fake_metadata(L,lua_tostring(L,-1));
			lua_pushnil(L); // fake error message
			lua_remove(L,-3); // err
			lua_remove(L,-4); // nil
		}
		lua_pop(L,1); // the erorr message
		lua_rawseti(L,METADATA,i+1);
		i=i+1;
		lua_pop(L,1);
	}
	updater_prg_page_download->value(100);
	updater_prg_page_download->copy_label(_("Done."));

	updater_chkbrw_select->clear();
	i=1;
	lua_pushnil(L);
	while (lua_next(L,METADATA) != 0) {
		int DATA = lua_gettop(L);
		val(NAME,lua_rawgeti(L,MODULES,i));
		val(VERSION,lua_getfield(L,DATA,"version"));
		val(LOCAL_VERSION,lua_getfield(L,DATA,"local_version"));
		val(CAN,lua_getfield(L,DATA,"can_update"));
		val(SHOULD,lua_getfield(L,DATA,"should_update"));
		val(WHY,lua_getfield(L,DATA,"why_cannot_update"));
		bool can = lua_toboolean(L,CAN);
		bool should = lua_toboolean(L,SHOULD);
		lua_pushboolean(L,can);
		lua_rawseti(L,UPGRADABLE,i);
		if (can && should)
			lua_pushfstring(L,_("%s: %s -> %s"),
				lua_tostring(L,NAME),lua_tostring(L,LOCAL_VERSION),	
				lua_tostring(L,VERSION));
		else if (can && !should) 
			lua_pushfstring(L,_("No need to update %s: %s"),
				lua_tostring(L,NAME),lua_tostring(L,WHY));
		else
			lua_pushfstring(L,_("Unable to update %s: %s"),
				lua_tostring(L,NAME),lua_tostring(L,WHY));

		updater_chkbrw_select->add(lua_tostring(L,-1),should && can);
		lua_pop(L,8);
		i++;
	}
	// save indeces for the download function
	upgradable=UPGRADABLE;
	metadata=METADATA;
	modules=MODULES;
	browser=BROWSER;
}

void updater_download(){
	updater_prg_page_download->value(0);
	int i,done;
	int checked = updater_chkbrw_select->nchecked();
	val(REPORT,lua_newtable(L));
	updater_prg_page_download->copy_label("");
	for (i=1,done=0; i < updater_chkbrw_select->nitems(); i++){
		if (updater_chkbrw_select->checked(i)) {
			val(NAME,lua_rawgeti(L,modules,i));
			// change progressbar
			updater_prg_page_download->value(done*100/checked);
			// set the lable
			lua_pushfstring(L,_("Downloading: %s"), lua_tostring(L,NAME));
			updater_prg_page_download->copy_label(lua_tostring(L,-1));
			lua_pop(L,1);
			// redraw
			Fl::check(); 
			// update if possible
			val(CAN,lua_rawgeti(L,upgradable,i));
			if (!lua_toboolean(L,CAN)) {
				// was selected but it can't be updated
				lua_pushstring(L,_("Not attempted."));
				lua_setfield(L,REPORT,lua_tostring(L,NAME));
			} else {
				// try the update
				/* for debugging: 
				 *   luay_printstack(L); 
				 *   fprintf(stderr, "NAME:%d browser:%d\n",NAME,browser); 
				 */
				int rc = luay_call(L,"sssv|vv", "updater_php.fetch_module",
					lua_tostring(L,NAME),"true","official",browser);
				if (rc != 0 || lua_isnil(L,-2)) {
					fl_alert(_("Error downloading %s:\n%s"),
						lua_tostring(L,NAME),lua_tostring(L,-1));
					lua_setfield(L,REPORT, lua_tostring(L,NAME));
				} else {
					lua_pushstring(L, _("Updated!"));
					lua_setfield(L,REPORT, lua_tostring(L,NAME));
				}
			}
			lua_pop(L,2);
			done++;
		}
	}
	updater_prg_page_download->value(100);
	updater_prg_page_download->copy_label(_("Done."));

	luaL_Buffer B;
	luaL_buffinit(L,&B);
	luaL_addstring(&B,"<html><head><title>");
	luaL_addstring(&B,_("Report"));
	luaL_addstring(&B,"</title></head><body><h1>");
	luaL_addstring(&B,_("Report"));
	luaL_addstring(&B,"</h1><ul>");

	if (updater_chkbrw_select->nchecked() > 0) {
		lua_pushnil(L);
		while (lua_next(L,REPORT) != 0) {
			luaL_addstring(&B,"<li><i>");
			luaL_addstring(&B,lua_tostring(L,-2));
			luaL_addstring(&B,"</i>: ");
			luaL_addstring(&B,lua_tostring(L,-1));
			luaL_addstring(&B,"</li>");
			lua_pop(L,1);
		}
	} else {
		luaL_addstring(&B,"<li>");
		luaL_addstring(&B,_("Did nothing!"));
		luaL_addstring(&B,"</li>");
	}

	luaL_addstring(&B,"</ul></body></html>");
	luaL_pushresult(&B);
	updater_hlp_page_html->value(lua_tostring(L,-1));
	lua_pop(L,1);
}

// vim: ts=4:
