/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                    *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	some libc for beos
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/
#ifdef BEOS

#include "beos_compatibility.h"

#ifndef index
char* index(const char * s, int i)
{
char* r=(char *)s;
while(*r != '\0')
	{
	if( *r == i)
		return r;

	r++;
	}
return NULL;
}
#endif

#endif
