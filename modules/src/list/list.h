/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   list.h
  * \brief  Polimorphic list data structure
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/

#ifndef LIST_H_
#define LIST_H_

#include <stdlib.h>
#include <stdio.h>

//!the list
typedef struct list_s
    {
    struct list_s* next;
    void *data;
    }list_t;

//! add an element, O(n)
extern list_t*  list_add	(list_t* l,void *data);
//! add an element, O(1) [the user must provide a temp pointer to the tail]
extern list_t*  list_add_fast	(list_t* l,list_t**tl,void *data);
//! remove the element (freed by the caller)
extern list_t*  list_remove	(list_t* l,list_t* elem);
//! sorts the list
extern list_t*  list_sort	(list_t* l,
		int (*compare)(void *data1,void* data2));
//! returns the handler of the node in wich x is
extern list_t*  list_find	(list_t *l,void* x,
		int (*is_equal)(void *x,void* data2));
//! makes a copy
extern list_t*  list_duplicate	(list_t *l,void* (*copyer)(void *data1));
//! deletes all
extern list_t*  list_free	(list_t *l,void (*destructor)(void *data1));
//! for each element
extern void 	list_visit	(list_t* l,void (*action)(void *));
//! return where x is
extern int 	list_getpos	(list_t *l,void* x,
		int (*compare)(void *data1,void* data2));
//! lenght
extern int	list_len	(list_t *l);
//! concatenates l1 and l2
extern list_t*  list_concat	(list_t *l1,list_t *l2);

//! uses the list as a stack, removing the head
extern list_t*  list_pop	(list_t *l);
//! uses the list as a stack, adding a head
extern list_t*  list_push	(list_t *l,void* data);
//! uses the list as a stack, getting the head [may call a pop after that]
extern void*  list_head	(list_t *l);

#endif
