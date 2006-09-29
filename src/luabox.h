/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   luabox.h
  * \brief  luaVM generation module
  * \author Enrico Tassi gareuselesinge<@users.sourceforge.net>
  */
/******************************************************************************/

#ifndef LUABOX_H
#define LUABOX_H

#define LUABOX_EMPTY	0

#define LUABOX_STANDARD	(1<<0)

#define LUABOX_POP3SERVER	(1<<1)
#define LUABOX_MLEX		(1<<2)
#define LUABOX_STRINGHACK	(1<<3)
#define LUABOX_SESSION		(1<<4)
#define LUABOX_CURL		(1<<5)
#define LUABOX_PSOCK		(1<<6)
#define LUABOX_BASE64		(1<<7)
#define LUABOX_GETDATE		(1<<8)
#define LUABOX_REGULAREXP	(1<<9)
#define LUABOX_LXP		(1<<10)
#define LUABOX_LOG		(1<<11)
#define LUABOX_CRYPTO		(1<<12)
#define LUABOX_LUAFILESYSTEM	(1<<13)
#define LUABOX_DPIPE		(1<<14)

#define LUABOX_FREEPOPS	(LUABOX_POP3SERVER|LUABOX_MLEX|LUABOX_STRINGHACK|\
			 LUABOX_SESSION|LUABOX_CURL|LUABOX_PSOCK|\
			 LUABOX_BASE64|LUABOX_GETDATE|LUABOX_REGULAREXP|\
			 LUABOX_LXP|LUABOX_LOG|LUABOX_CRYPTO|\
			 LUABOX_LUAFILESYSTEM|LUABOX_DPIPE)

#define LUABOX_FULL (LUABOX_STANDARD|LUABOX_FREEPOPS)

#define LUABOX_LAST 15

//! generates a luaVM loading initial_stuff libraries
lua_State* luabox_genbox(unsigned long intial_stuff);

//! loads into box the stuff libraries
void luabox_addtobox(lua_State* box,unsigned long stuff);

#endif 
