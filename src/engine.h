/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   engine.h
  * \brief  Drivers for the popserver
  * \author Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef ENGINE_H
#define ENGINE_H

#include "popserver.h"
#include "popstate.h"
#include "lua.h"

/**
 * \brief this struct is the implementation of webmail access
 *
 *
 */ 
extern struct popserver_functions_t freepops_functions;

/**
 * \brief Use this to bootstrap a LUA VM
 *
 * Starts the VM with the freepops stuff, if username is NULL only
 * freepops.bootstrap is called, else freepops.init(username) and init(p).
 *
 * should be put in another module I think
 */ 
extern lua_State* bootstrap(char* username, struct popstate_t*p);

#endif

