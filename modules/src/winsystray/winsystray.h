/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************/
 /*!
  * \file   winsystray.h
  * \brief  windows tray icon
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/
#ifndef WINSYSTRAY_H
#define WINSYSTRAY_H

#ifdef WIN32

#include <windows.h>

void create_tray_icon(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    LPSTR lpszCmdLine, int nCmdShow);

int parse_commandline(char*** argv,char* str);

#endif

#endif
