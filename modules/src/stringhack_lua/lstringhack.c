/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://freepops.sf.net)                     *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	some hacks
 * Notes:
 *	
 * Authors:
 * 	Name <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/
#include <stdlib.h>
#include <stdio.h>

#include "lstringhack.h"
#include "regularexp.h"

#include "win32_compatibility.h"

#include "log.h"
#define LOG_ZONE "STRINGHACK"

struct strhack_t
	{
	int header_done;
	long int current_lines;
	char last3[4];
	char last4[4];
//	char* to_free_top;
//	char* to_free_dot;
	};

struct strhack_t* new_str_hack()
{
struct strhack_t* tmp;

tmp = malloc(sizeof(struct strhack_t));

MALLOC_CHECK(tmp);

tmp->header_done = 0;
tmp->current_lines = 0;
memset(tmp->last3,'\0',4);		
memset(tmp->last4,'\0',4);		
//tmp->to_free_top = NULL;
//tmp->to_free_dot = NULL;

return tmp ;
}

void delete_str_hack(struct strhack_t* x)
{
//free(x->to_free_top);
//free(x->to_free_dot);
free(x);
}

/*! gets a string, plus a static buffer char last [4]
 *  and return a buffer with all the \n\r.\n replaced
 *  with \n\r..\n even if fragmented between two subsequest
 *  calls. buff must be dynamic memory, and the result should be free
 *  by the client, while buff is eventually freed by this function.
 *
 */ 
char * dothack(struct strhack_t*a,const char *buff)
{
char defrag[7];
int p;
int n;
char* rc;
char* last = a->last4;

if(buff == NULL)
	return NULL;

//buff = strdup(buff);

memset(defrag,'\0',7);

strcpy(defrag,last);
strncpy(&defrag[strlen(last)],buff,3);
defrag[strlen(last)+3]='\0';

p = regfind_start(defrag,"\r\n\\.\r");
if(p != -1)
	{
	//fragmented!
	char* idx;
	int d;
	//printf("!!FRAG ->%s<-!!\n",defrag);

	idx = index(defrag,'.');
	if(idx == NULL)
		{
		//printf("!!ERROR\n");
		ERROR_PRINT("not a '.'\n");
		}
	
	d  = idx - defrag;

	//printf("!!d=%d\n",d);
	
	switch(d) 
		{
		case 0:
		case 1:
		case 5:
			//printf("!!skip\n");
			break;
		case 2:
		case 3:
		case 4:
			{
			char * rc = calloc(strlen(buff)+ 2,sizeof(char));

			memcpy(rc,&("\n.."[4-d]),d);

			strcat(&rc[d-1],&buff[d-2]);
			
			//free(buff);
			buff = (const char*)rc;

			/*
			if (a->to_free_dot != NULL)
				free(a->to_free_dot);
			a->to_free_dot = buff;
			*/
			
			}
			break;
		default:
			//printf("!!ERROR\n");
			ERROR_PRINT("not in case!\n");
			break;
		}
	
	}

n = regfind_count(buff,"\r\n\\.\r",1);
//printf("!!%d!!\n",n);
if(n>0)
	{
	int i,o;
	rc = calloc(strlen(buff) + 1 + n,sizeof(char));
	for(i=0,o=0;n>0;i++,o++)
		{
		//printf("!!comparing %s!!\n",&buff[i]);
		if(!strncmp(&buff[i],"\r\n.\r",4))
			{
			memcpy(&rc[o],"\r\n..\r",5);
			o+=5-1;
			i+=4-2;
			n--;
			//printf("!!GOT!!\n");
			}
		else
			{
			rc[o] = buff[i];			
			}
		}
	
	if(i<strlen(buff))
		{
		strcat(&rc[o],&buff[i]);
		}
	
	//free(buff);
	
	// this if should be always true
	/*
	if (a->to_free_dot != NULL)
		free(a->to_free_dot);
	a->to_free_dot = rc;
	*/
	}
else	
	{
	rc = (char *)buff;
	}

memcpy(last,&rc[strlen(rc) - 3],4);

return rc;
}

// returned value is tmp
char *tophack(struct strhack_t *a,const char* tmp,int lines)
{
char* buff = NULL;
if(!a->header_done)
	{
	regmatch_t pm;
	char defrag[7];

	// build the defrag
	memset(defrag,'\0',7);
	strncat(defrag,	a->last3,3);
	strncat(defrag,tmp,3);

	//DBG("DEFRAG='%s'\n",defrag);

	//search first here
	pm = regfind(defrag,"\r\n\r\n");

	if(pm.begin == -1)
		{
		//not fragmented :)
		//DBG("NOT FRAGMENTED!!\n");
			
		//search for the end of header
		pm = regfind(tmp,"\r\n\r\n"); 
			
		if( pm.begin != -1)
			{
			a->header_done = 1;
			a->current_lines = 
			regfind_count(&tmp[pm.end],"\r\n",0);
			}
		}
	else
		{
		//DBG("!! FRAGMENTED !!\n");	
		// the end of the header tag is fragmented
		a->header_done = 1;
		a->current_lines = regfind_count(tmp,"\r\n",0);
				
		// if ..R|NRN or .RN|RN. current_lines--
		pm = regfind(defrag,"..\r\n\r\n");
		if(pm.begin != -1)
			a->current_lines--;
		pm = regfind(defrag,".\r\n\r\n.");
		if(pm.begin != -1)
			a->current_lines--;
				
		}

	//save last3
	snprintf(a->last3,
		4,"%s",&tmp[strlen(tmp)-3]);
	}
else
	{
	a->current_lines += regfind_count(tmp,"\r\n",0);
	}

/* have we received more than needed? */
if (a->current_lines > lines || (lines == 0 && a->header_done))
	{
	int i;
	int l,l_old;

	/*
	if (a->to_free_top != NULL)
		free(a->to_free_top);
	*/

	buff = strdup(tmp);
	/*a->to_free_top = tmp;*/


	//DBG("cutting %ld\n",a->current_lines - lines);
		
	l = l_old = strlen(buff) - 2;

	if(lines == 0)
		i = -1; // we have t oremove the blank line!
	else
		i = 0;
		
	//return back from the end of
	while( i <= a->current_lines - lines && l >= 0)
		{
		if(!strncmp(&buff[l],"\r\n",2))
			{
			i++;
			l--; //skip 2 == strlen("\r\n")
			//DBG("CUT %d\n$\n%s\n$\n",i,&buff[l]);
			}
		l--;
		}
	if(l>=0)
		l+=2;
		
	// fix it putting a \0
	if(l>=0)
		{
		//DBG("(%d)cutting from here:\n$\n%s\n$\n",l,&tmp[l]);
		if(l_old - l >= 3)
			{
			buff[l+2]='\0';
			buff[l+1]='\n';
			buff[l+0]='\r';
			}
		else if(l_old - l >= 1)
			{
			buff[l]='\0';
			}
		}
	}
else
	buff= (char *)tmp;

return buff;
}

int check_stop(struct strhack_t *a,int lines)
{
if (a->current_lines > lines || (lines == 0 && a->header_done))
	return 1;
else
	return 0;
}

int current_lines(struct strhack_t *a)
{
return a->current_lines;
}

