#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

int c99_snprintf(const char *fmt,...)
{
/* Guess we need no more than 100 bytes. */
int n, size = 100;
char *p;
va_list ap;

if ((p = malloc (size)) == NULL)
	return -1;
while (1) 
	{
	/* Try to print in the allocated space. */
	va_start(ap, fmt);
	n = vsnprintf (p, size, fmt, ap);
	va_end(ap);
	
	/* If that worked, return the string. */
	if (n > -1 && n < size)
		return size;
	/* Else try again with more space. */
	if (n > -1)    /* glibc 2.1 */
		size = n+1; /* precisely what is needed */
	else           /* glibc 2.0 */
		size *= 2;  /* twice the old size */
	if ((p = realloc (p, size)) == NULL)
	return -1;
	}
}

int c99_vsnprintf(const char *fmt, va_list ap)
{
int n, size = 100;
char *p;
if ((p = malloc (size)) == NULL)
	return -1;
while (1) 
	{
	/* Try to print in the allocated space. */
	n = vsnprintf (p, size, fmt, ap);
	
	/* If that worked, return the string. */
	if (n > -1 && n < size)
		return size;
	/* Else try again with more space. */
	if (n > -1)    /* glibc 2.1 */
		size = n+1; /* precisely what is needed */
	else           /* glibc 2.0 */
		size *= 2;  /* twice the old size */
	if ((p = realloc (p, size)) == NULL)
	return -1;
	}
}

