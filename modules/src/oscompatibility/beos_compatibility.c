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
