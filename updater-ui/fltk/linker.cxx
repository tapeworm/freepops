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

/* ========================================================================= */
// global values that contain the position in the lua stack of some objects
static int upgradable; // name |--> bool
static int metadata; // name |--> metadata table
static int browser; // the browser object, always the same to reuse connections
static int name2pos; // name |--> position in the checklist

/* ========================================================================= */
// download the metadata of all modules
// leaves on the stack 3 tables and a browser object
void updater_download_metadata(){
	lua_pop(L,lua_gettop(L));
	updater_prg_page_download->value(0);
	updater_prg_page_download->copy_label(_("Downloading: plugin list"));
	Fl::check();

	// the browser object
	val(BROWSER, luay_call(L,"|v","browser.new"));
	// the table to contain all metadata
	val(METADATA,lua_newtable(L));
	// the table to contain al modules that can be updated
	val(UPGRADABLE,lua_newtable(L));
	// the table that associate names with positions in the checklist
	val(NAME2POS,lua_newtable(L));

	/* debug:
	 *  luay_printstack(L);
	 *  fprintf(stderr,"BROWSER: %d METADATA: %d UPGRADABLE: %d NAME2POS: %d\n",
	 *   	BROWSER,METADATA,UPGRADABLE,NAME2POS);
	 */  

	// the table that lists all plugin names
	int rc = luay_call(L,"s|vv","updater.list_modules","official");
	if (rc != 0 || lua_isnil(L,-2)) {
		fl_alert(_("Unable to download the module list:\n%s"),
			lua_tostring(L,-1));
		updater_failure();
		return;
	}
	lua_pop(L,1); // the erorr message
	val(MODULES,);

	val(NAMES,rc=luay_call(L,"vs|v", "table.concat",MODULES,","));
	if (rc != 0 || lua_isnil(L,NAMES)) {
		fl_alert(_("Unable to concatenate modules list"));
		updater_failure();
		return;
    }
	
	// change progressbar
	updater_prg_page_download->value(1*100/lua_objlen(L,MODULES));

	// set the lable
	lua_pushfstring(L,_("Downloading %d metadata records"),
		lua_objlen(L,MODULES));
	updater_prg_page_download->copy_label(lua_tostring(L,-1));
	lua_pop(L,1);
	// redraw
	Fl::check(); 

	rc = luay_call(L,"vsv|vv","updater.fetch_module_metadata",
		NAMES,"official",BROWSER);
	if (rc != 0 || lua_isnil(L,-2)) {
		fl_alert(_("Unable to download the module metadata:\n%s"),
			lua_tostring(L,-1));
		updater_failure();
		return;
    }
	lua_pop(L,1); // the erorr message

	for (size_t i = 1; i < lua_objlen(L,-1); i++){
		val(MDATA,lua_rawgeti(L,-1,i));
		val(NAME,lua_getfield(L,MDATA,"module_name"));
		lua_pushvalue(L,MDATA);
		lua_setfield(L,METADATA,lua_tostring(L,NAME));
		lua_pop(L,2);
	}
	lua_pop(L,1); // the table returned by fetch_module_metadata
	lua_pop(L,1); // the result of table.concat
	lua_pop(L,1); // the table with the names of the modules

	// change progressbar
	updater_prg_page_download->value(100);
	updater_prg_page_download->copy_label(_("Done."));

	updater_chkbrw_select->clear();
	int i=1;
	lua_pushnil(L);
	while (lua_next(L,METADATA) != 0) {
		int NAME = lua_gettop(L)-1;
		int DATA = lua_gettop(L);
		val(VERSION,lua_getfield(L,DATA,"version"));
		val(LOCAL_VERSION,lua_getfield(L,DATA,"local_version"));
		val(CAN,lua_getfield(L,DATA,"can_update"));
		val(SHOULD,lua_getfield(L,DATA,"should_update"));
		val(WHY,lua_getfield(L,DATA,"why_cannot_update"));
		bool can = lua_toboolean(L,CAN);
		bool should = lua_toboolean(L,SHOULD);
		lua_pushboolean(L,can);
		lua_setfield(L,UPGRADABLE,lua_tostring(L,NAME));
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

		// add it to the checklist and save its position
		updater_chkbrw_select->add(lua_tostring(L,-1),should && can);
		lua_pushnumber(L,i);
		lua_setfield(L,NAME2POS,lua_tostring(L,NAME));

		lua_pop(L,7);
		i++;
	}
	// save indeces for the download function
	name2pos=NAME2POS;
	upgradable=UPGRADABLE;
	metadata=METADATA;
	browser=BROWSER;
}

/* ========================================================================= */
// download the plugins and generates the report
void updater_download(){
	updater_prg_page_download->value(0);
	int i,done;
	int checked = updater_chkbrw_select->nchecked();
	val(REPORT,lua_newtable(L));
	updater_prg_page_download->copy_label("");
	
	i=1;
	done=0;
	lua_pushnil(L);
	while (lua_next(L,metadata) != 0) {
		lua_pop(L,1); // data is not important, only name is used
		int NAME = lua_gettop(L);

		// get the position of the module in the checklist
		lua_getfield(L,name2pos,lua_tostring(L,NAME));
		lua_Integer position = lua_tointeger(L,-1);
		lua_pop(L,1);

		if (updater_chkbrw_select->checked(position)) {
			// change progressbar
			updater_prg_page_download->value(done*100/checked);
			// set the lable
			lua_pushfstring(L,_("Downloading: %s"), lua_tostring(L,NAME));
			updater_prg_page_download->copy_label(lua_tostring(L,-1));
			lua_pop(L,1);
			// redraw
			Fl::check(); 
			// update if possible
			val(CAN,lua_getfield(L,upgradable,lua_tostring(L,NAME)));
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
				int rc = luay_call(L,"vssv|vv", "updater.fetch_module",
					NAME,"true","official",browser);
				if (rc != 0 || lua_isnil(L,-2)) {
					fl_alert(_("Error downloading %s:\n%s"),
						lua_tostring(L,NAME),lua_tostring(L,-1));
					lua_setfield(L,REPORT, lua_tostring(L,NAME));
					lua_pop(L,1); // the first nil returned
				} else {
					lua_pushstring(L, _("Updated!"));
					lua_setfield(L,REPORT, lua_tostring(L,NAME));
					lua_pop(L,1); // the nil error message
				}
			}
			lua_pop(L,1); // the 'can' field
			done++;
		} 
		i++;
	}
	updater_prg_page_download->value(100);
	updater_prg_page_download->copy_label(_("Done."));

	// generate the HTML report
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
	lua_pop(L,1); // the buffer content
}

// vim: ts=4:
