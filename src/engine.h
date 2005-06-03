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
 * \brief Use this to launch custom modules
 *
 * should be put in another module I think
 */ 
extern void bootstrap(struct popstate_t*p,lua_State* l,char* username,int loadonly);

#endif

