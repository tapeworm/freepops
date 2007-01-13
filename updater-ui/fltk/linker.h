/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   linker.h
  * \brief  fltk-updater to freepops bridge
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/

#ifndef LUA_LINKER_H
#define LUA_LINKER_H

#include <lua.hpp>

extern void updater_init(lua_State* l);
extern void updater_download_metadata(void);
extern void updater_download(void);
#endif

