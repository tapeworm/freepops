/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *      regex wrapper
 * Notes:
 *
 * Authors:
 *	Enrico Tassi <gareuselsinge@users.sourceforge.net>
 *	Alessio Caprari <alessiofender@users.sourceforge.net>
 ******************************************************************************/

#include <stdlib.h>
#include <sys/types.h>
#include <regex.h>
#include <stdio.h>

#include "regularexp.h"

regmatch_t regfind(const char* from,const char* exp)
{
int errcode;
regex_t r;
regmatch_t pm[1]={{-1,-1}};

if(from == NULL)
	return pm[0];

errcode = regcomp(&r,exp,REG_ICASE|REG_NEWLINE|REG_EXTENDED);
if (errcode != 0) {
	char *errbuf = NULL;
	size_t errbuf_size;
	
	errbuf_size = regerror(errcode, &r, errbuf, 0);
	errbuf = (char *)malloc(errbuf_size);
	if (errbuf != NULL) {
		regerror(errcode, &r, errbuf, errbuf_size);
		fprintf(stderr,"ERROR: Internal compiling regexp '%s', %s\n", exp, errbuf);
		free(errbuf);
	} else {
		fprintf(stderr,"ERROR: Internal compiling regexp' %s'\n", exp);
	}
}	

regexec(&r,from,1,pm,0);

regfree(&r);

return pm[0];
}

/* Return only the start offset */
inline regoff_t regfind_start(const char* from, const char* end)
{
regmatch_t pm;

pm = regfind(from, end);

return pm.begin;
}

/* Return only the end offset */
inline regoff_t regfind_end(const char* from, const char* end)
{
regmatch_t pm;

pm = regfind(from, end);

return pm.end;
}

/* slow! */
int regfind_count(const char* from, const char* exp, int offset)
{
regmatch_t pm;
int n = 0;

pm.begin = 0;
pm.end = 0;

pm = regfind(from,exp);
while(pm.begin != -1)
	{
	n++;
	//printf("trovato a partire da %d e fino a %d, riparto da %ld\n",
	//	pm.begin,pm.end,pm.end - offset);
	from += pm.end - offset;
	pm = regfind(from,exp);
	}

return n;
}

