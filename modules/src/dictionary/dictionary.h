/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   dictionary.h
  * \brief  a dictionary data structure. list of (key,data) couples
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/


#include "list.h"

//! a dictionary
struct dictionary_t 
	{
	list_t *head;
	};

/**
 * \brief find an element
 * 
 * \param d the dictionary
 * \param key the key
 * \return the data associated with key or NULL
 */ 
void* dictionary_find(struct dictionary_t *d,const char* key);

/**
 * \brief remove the element associated with key
 *
 * \param d the dictionary
 * \param key the key
 * \return 0 on success
 *
 */ 
int dictionary_remove(struct dictionary_t *d,const char* key);

/**
 * \brief adds the element and associats it with the key
 *
 * \param d the dictionary
 * \param key the key
 * \param data the element
 * \return 0 on success
 *
 */int dictionary_add(struct dictionary_t *d,const char* key,void *data);

