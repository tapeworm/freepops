/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   registry.h
  * \brief  windows hell door
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/

#ifdef WIN32
extern int string_marshal(char *, void *, char *, char *, int);
extern int int_marshal(char *, void *, char *, char *, int);
//! get the specified key from the registry
extern void get_key_value_as(HKEY root, const char *path,
        int(*regmarshal)(char*,void*,char*,char*,int), char *param, void *ret);
extern void set_key_value_as_string(
	HKEY root,const char*path,const char * key, const char * val);

#endif

