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

/**
 * \brief build a dictionary
 *
 * \return a dictionary
 */ 
struct dictionary_t * dictionary_create();

/**
 * \brief find an element
 *  note that the value of res is not ensured to be atill valid,
 *  you can implement it op
 * \param d the dictionary
 * \param key the key
 * \param op if not NULL this operation is called on the data
 *        while being in mutual exclusion
 * \param res the data associated with key is set there if res != NULL
 * \return the result of operation if any operation is set, default 0
 */ 
int dictionary_find(
	struct dictionary_t *d,const char* key,void **res, int (*op)(void *));

/**
 * \brief remove the element associated with key
 *
 * \param d the dictionary
 * \param key the key
 * \param op if not NULL this operation is called on the data
 *        while being in mutual exclusion, if it returns != 0 then removal 
 *        is not performed
 * \param freedata if not NULL is used to free the data 
 * \return the result of operation if any operation is set, default 0
 *
 */ 
int dictionary_remove(
	struct dictionary_t *d,const char* key,
	int (*op)(void *),void(*freedata)(void*));

/**
 * \brief adds the element and associats it with the key
 *
 * \param d the dictionary
 * \param key the key
 * \param data the element
 * \param freedata if not NULL add overwrites freeing the previous data 
 *        with that function
 * \param op if not NULL this operation is called on the data
 * 	  that may be already present if it returns != 0 then addition 
 * 	  is not performed and the freedata function is not called
 * \return 0 or 1 on success (0 if freedata was called, 1 if not)
 *
 */
int dictionary_add(
	struct dictionary_t *d,const char* key,
	void *data,int (*op)(void *),void(*freedata)(void*));

