/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *      
 * Notes:
 *
 * Authors:
 *      Alessio Caprari <alessio.caprari@tiscali.it>
 *      Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
 *      Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include "list.h"
#include "win32_compatibility.h"

#define HIDDEN static
#define MALLOC_CHECK(a) {if((a)==NULL){fprintf(stderr,"%s %d: malloc failed\n",__FILE__,__LINE__);abort();}}

/***********************************************************************
 *   adds an element to the end
 */
list_t* list_add(list_t* l,void *data)
{
if( l == NULL )
	{
        list_t* tmp;
        tmp = (list_t*) malloc(sizeof(list_t));
	MALLOC_CHECK(tmp);
        tmp->next = NULL;
        tmp->data = data;
        return(tmp);
        }
else
	{
	l->next = list_add(l->next,data);
	return(l);
	}
}

/***********************************************************************
 *   adds an element to the end
 */
list_t*  list_add_fast	(list_t* l,list_t**tl,void *data)
{
list_t* tmp;
tmp = (list_t*) malloc(sizeof(list_t));
MALLOC_CHECK(tmp);
tmp->next = NULL;
tmp->data = data;
	
if( l == NULL )
	{
        *tl = tmp;
        return(tmp);
        }
else
	{
	(*tl)->next = tmp;
	*tl = tmp;
        return(l);
	}

}
/***********************************************************************
 *   removes an element(you must free it yourself)
 */

list_t* list_remove(list_t* l,list_t* elem)
{
if ( elem == l )
	{
	list_t* tmp = l->next;
	
	free(l); // it assumes that you have freed l->data
	
	return(tmp);
	}
else if( l != NULL)
	{
	l->next = list_remove(l->next,elem);
	return(l);
	}
else
	{// elem not found
	return(NULL);
	}
}

/***********************************************************************
 *   sort
 */


HIDDEN list_t *list_max(list_t *l,int (*compare)(void *data1,void* data2))
{
     if (l==NULL) return(NULL);
else if (l!=NULL && l->next==NULL) return(l);
else 	
	{
	l->next=list_max(l->next,compare);
	if (compare(l->data ,l->next->data) > 0)
		{
		list_t *tmp;
		tmp=l->next;
		
				
		l->next=tmp->next;
		tmp->next=l;
		return(tmp);		

		}
	else return(l);

	}

}
list_t *list_sort(list_t *l,int (*compare)(void *data1,void* data2))
{
if (l==NULL) return(l);
else
	{
	l=list_max(l,compare);
	l->next=list_sort(l->next,compare);
	return(l);
	}
}


/***********************************************************************
 *   returns the list* that contains x
 */


list_t* list_find(list_t *l,void* x,int (*equal)(void *x,void* data2))
{
if ( l == NULL )
	return NULL;
else
	{
	if ( equal(x,l->data) )
		{
		return(l);
		}	
	else return(list_find(l->next,x,equal));
	}

}


/***********************************************************************
 *
 */


list_t* list_duplicate(list_t *l,void* (*copier)(void *data1))
{
if ( l == NULL )
	return NULL;
else
	{
	list_t *tmp;
	
	tmp = malloc(sizeof(list_t ));
	MALLOC_CHECK(tmp);
	tmp ->data = copier(l->data);	
	
	tmp->next = list_duplicate(l->next,copier);
	return(tmp);
	}
}

/***********************************************************************
 *   delete each element
 */

/* 	
list_t* list_free(list_t *l,void (*fr)(void *data1))
{
if ( l != NULL)
	{
	// assignment is useless	
	l->next = list_free(l->next,fr);
	

	if(fr != NULL)
		fr(l->data);
	
	free(l);
	}
return NULL;
}
*/

list_t* list_free(list_t *l,void (*fr)(void *data1))
{
while (l != NULL)
	{
	list_t* next = l->next;

	if(fr != NULL)
		fr(l->data);
	
	free(l);

	l = next;
	}
return NULL;
}


/***********************************************************************
 *   action on each element
 */


void list_visit(list_t* l,void (*pr)(void *))
{
while( l != NULL )
	{
	pr(l->data);
	l=l->next;
	}
}


/***********************************************************************
 *   gets the position of x
 */


int 	 list_getpos(list_t *l,void* x,int (*equal)(void *data1,void* data2))
{
if( l == NULL)
	{
	return -1;
	}
if ( equal(x,l->data) )
	return(0);
else
	return (1 + list_getpos(l->next,x,equal));
}

/***********************************************************************
 *   counts elements
 */


int	 list_len(list_t *l)

{
if( l == NULL)
	{
	return 0;
	}
else
	{
	return (1 + list_len(l->next) );
	}
		
}

/***********************************************************************
 *   concatenates the 2 lists returning the merged list.
 */


list_t*  list_concat	(list_t *l1,list_t *l2)
{
list_t* tmp=l1;

if(l1 == NULL)
	return l2;
if(l2 == NULL)
	return l1;

while( tmp->next != NULL)
	tmp = tmp->next;

tmp -> next = l2;

return l1;
}

//! uses the list as a stack, removing the head
list_t*  list_pop	(list_t *l)
{
list_t* tmp;

if(l != NULL)
	tmp = l->next;
else
	tmp = NULL;

free(l);
return tmp;
}

//! uses the list as a stack, adding a head
extern list_t*  list_push	(list_t *l,void* data)
{
list_t* tmp;
tmp = (list_t*) malloc(sizeof(list_t));
MALLOC_CHECK(tmp);
tmp->next = l;
tmp->data = data;
return tmp;
}

//! uses the list as a stack, getting the head [may call a pop after that]
extern void*  list_head	(list_t *l)
{
if(l != NULL)
	return l->data;
else
	return NULL;
}
