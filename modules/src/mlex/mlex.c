/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	Markup Language EXpressions
 * Notes:
 *	This version supports optional tags/strings and the backtrack
 *	tends to be a bit slower.
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <string.h>
#include <time.h>

#include "regularexp.h"
#include "list.h"
#include "mlex.h"

#include "log.h"
#define LOG_ZONE "MLEX"

//#define DEBUG_MLEX 1

#define HIDDEN static

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */
/*** local types/macro  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */
/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */

#define TOK_STR		0
#define TOK_TAG		1
#define TOK_OPT_TAG	2
#define TOK_OPT_STR	4

#define MATCHES 	1
#define NOT_MATCHES 	0

//! used to represent answers
struct answer_t
	{
	list_t* start;
	int len;
	list_t* dust_lengths;
	};

//! used for tokenization
struct token_t
	{
	int start,stop;
	short tag;
	int dustlen;
	};

//! used for backtracking
struct back_t
	{
	list_t* dust_lengths;
	list_t* position_stream;
	list_t* position_expr;
	int len;
	};

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */
/*** prototypes divided by section  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */
/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */

/*** tokenization ***/
HIDDEN void regexec_my(char* s,regmatch_t *p, int *bag);
HIDDEN void regexec_myext(char* s,regmatch_t *p);
HIDDEN list_t *tokenize_html(char* t);
HIDDEN list_t *tokenize_exp(char* t);

/*** matching ***/
HIDDEN regmatch_t token_match(struct token_t* t,char* s,char* exp);
HIDDEN int token_match_token(struct token_t* t,char* s,struct token_t *t1,
	char* s1);
HIDDEN unsigned int mlmatch_find(list_t *data,list_t* pattern,char* str,
	char* exp,list_t*saved_pattern,list_t*stack,int len);
HIDDEN int is_a_keep(void* x,char* str);

/*** result refinement ***/
HIDDEN list_t* epurate(list_t* data,int len,list_t* dl,char* txt,list_t* get,
	char* str);
HIDDEN list_t* mlmatch_epurate(list_t* ans,char* txt, list_t* get,char* str);

/*** result handling ***/
HIDDEN struct chunk_t* mlmatch_get_x(list_t* l,int pos);
HIDDEN list_t* mlmatch_get_y(list_t* l,int pos);
HIDDEN char *mlmatch_get(struct chunk_t*c,char* str);

/*** aux ***/
HIDDEN void mlmatch_print_results_aux(list_t*res,char* str);
HIDDEN list_t* mlmatch_aux(list_t *data,list_t* pattern,char* str,char* exp,
	int min_len);		
/*** helpers ***/
HIDDEN void restore_dusts(list_t* orig, list_t* copy);
HIDDEN list_t * copy_dusts(list_t *orig);
HIDDEN void clean_stack(list_t* stack);
HIDDEN void reset_dustlen(list_t* pattern);
HIDDEN int exp_min_len(list_t* l);

/*** free ***/
HIDDEN void free_sublist(void* l);
HIDDEN void free_answer(void *f);
	
/*** new ***/
HIDDEN void * new_int(int i);
HIDDEN list_t* new_dust_lengths(list_t* exp);
HIDDEN struct chunk_t * new_chunk(int start,int stop);
HIDDEN struct answer_t* new_answer(list_t* start,int len,list_t* exp);
HIDDEN struct token_t *new_token(int start,int stop,short tags);

/*** print ***/
HIDDEN void print_token(struct token_t *c, char *s);
HIDDEN void print_toklist(list_t*l, char *s, int i);
HIDDEN void print_toklistn(list_t*l, char *s,int n);
HIDDEN void print_chunk(struct chunk_t*c, char* str);
#ifdef DEBUG_MLEX
HIDDEN void print_int(void*x);
#endif
HIDDEN void print_anslist(list_t *a,char* str);

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */
/*** the code  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */
/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: tokenization ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * to be used wit an HTML string, finds the fist token
 * a token is a tag, or a comment or a <script></script>
 *
 */ 
#define MODE_SCRIPT 1
#define MODE_PLAIN 0
HIDDEN __inline__ int scriptmatch(char* s){
int pos = 0;

while (s[pos] == ' ') pos++;
if (s[pos] == '/') pos++;

if (s[pos] == '\0' || (s[pos] != 's' && s[pos] != 'S')) return MODE_PLAIN;
pos++;
if (s[pos] == '\0' || (s[pos] != 'c' && s[pos] != 'C')) return MODE_PLAIN;
pos++;
if (s[pos] == '\0' || (s[pos] != 'r' && s[pos] != 'R')) return MODE_PLAIN;
pos++;
if (s[pos] == '\0' || (s[pos] != 'i' && s[pos] != 'I')) return MODE_PLAIN;
pos++;
if (s[pos] == '\0' || (s[pos] != 'p' && s[pos] != 'P')) return MODE_PLAIN;
pos++;
if (s[pos] == '\0' || (s[pos] != 't' && s[pos] != 'T')) return MODE_PLAIN;

return MODE_SCRIPT;
}

HIDDEN void regexec_my(char* s,regmatch_t *p, int* mode)
{
int pos;
int dust;
int sm = MODE_PLAIN;

p->begin = -1;
p->end = -1;
	
for(pos = 0 ; !(
	s[pos] == '\0' || 
	(s[pos] == '<' && (((sm=scriptmatch(&s[pos+1])) == MODE_SCRIPT) || 
	 *mode == MODE_PLAIN ))) ; pos++);
	
if(s[pos] == '\0')
	return;

#ifdef DEBUG_MLEX
printf("STOP: s[pos] == %c, *mode = %d, next are %c%c%c%c%c%c sm = %d\n",
	s[pos],*mode,s[pos+1],s[pos+2],s[pos+3],s[pos+4],s[pos+5],s[pos+6],sm);
#endif

p->begin  = pos;

dust=0;
if(*mode != MODE_SCRIPT && !strncmp(&s[pos],"<!--",4))
	dust=1;

pos++;

while(1)
	{
	if(s[pos] == '\0')
		break;
	else if (s[pos] == '>')
		{
		if(dust == 1)
			{
			if(s[pos-1] == '-' && s[pos-2] == '-')
				break;
			}
		else 
			{
			if (*mode == MODE_SCRIPT)
				{
				if (scriptmatch(&s[pos-6]))
					break;
				} 
			else
				break;
			}
		}
	pos++;
	}

if(s[pos] == '\0')
	{
	p->begin = -1;
	return;
	}

if ( *mode == MODE_SCRIPT)
	*mode = MODE_PLAIN;
else if ( *mode == MODE_PLAIN)
	*mode = sm;

p->end = pos+1;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * to be used wit an HTML string, finds the fist token
 * a token is a <tag>, a {tag} or a [string] 
 */
HIDDEN void regexec_myext(char* s,regmatch_t *p)
{
int pos;
p->begin = -1;
p->end = -1;
	
for(pos = 0 ; s[pos] != '<' && s[pos] != '{' && s[pos] != '\0' ; pos++);

if(s[pos] == '\0')
	return;
	
p->begin  = pos;

for(; s[pos] != '>' && s[pos] != '}' && s[pos] != '\0' ; pos++);

if(s[pos] == '\0')
	{
	p->begin = -1;
	return;
	}

p->end = pos+1;

}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * Splits an html string in tokens
 * 
 */
HIDDEN list_t *tokenize_html(char* t)
{
list_t * l = NULL,*tl=NULL;
int position=0;
regmatch_t p[1];
unsigned int len = strlen(t);

int bag = MODE_PLAIN;

do	{
	p[0].begin = -1;
	p[0].end = -1;
	regexec_my(&t[position],p,&bag); // faster, but not so much
	if(p[0].end != -1) 
		{
		int start1,start2,stop1,stop2;
	
		start2 = position+p[0].begin;
		stop2= position+p[0].end;

		start1=position;
		stop1=position+p[0].begin;
	
		l=list_add_fast(l,&tl,new_token(start1,stop1,0));
		if(start2+1 < stop2-1)
			l=list_add_fast(l,&tl,
				new_token(start2+1,stop2-1,TOK_TAG));
		}
	position+=p[0].end;
	} 
while(p[0].begin != -1 && position < len);

return l;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * Splits an expression string in tokens
 * 
 */
HIDDEN list_t *tokenize_exp(char* t)
{
list_t * l = NULL,*tl=NULL;
int position=0;
regmatch_t p[1];

do	{
	p[0].begin = -1;
	p[0].end = -1;
	regexec_myext(&t[position],p); // faster, but not so much
	if(p[0].end != -1) 
		{
		int start1,start2,stop1,stop2;
	
		start2 = position+p[0].begin;
		stop2= position+p[0].end;

		start1=position;
		stop1=position+p[0].begin;
	
		if (t[start1] == '[')
			l=list_add_fast(l,&tl,
				new_token(start1+1,stop1-1,TOK_OPT_STR));	
		else
			l=list_add_fast(l,&tl,new_token(start1,stop1,0));
			
		if(start2+1 < stop2-1)
			{
			int tag = TOK_TAG;

			if (t[start2] == '{')
				tag |= TOK_OPT_TAG;
			
			l=list_add_fast(l,&tl,new_token(start2+1,stop2-1,tag));
			}
		}
	position+=p[0].end;
	} 
while(p[0].begin != -1);

return l;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: matching ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * is x a keep 'X' or a drop 'O' ?
 *
 */
HIDDEN int is_a_keep(void* x,char* str)
{
struct token_t* t = (struct token_t*)x;

#ifdef DEBUG_MLEX
printf("ACTING ");
print_token(x,str);
printf("\n");
#endif

if( t->start == t->stop)
	return 0;
else if( str[t->start] == 'X')
	return 1;
else if( str[t->start] == 'O')
	return 0;
else if(str[t->start] == '\0')
	return 0;
else
	DBG("we got a '%c'\n",str[t->start]);
	DBG("string was '%s'\n",&str[t->start]);
	ERROR_ABORT("Internal error : not X nor O");
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * regularexp match on a token t on string s of 
 * exprssion exp
 *
 */
HIDDEN regmatch_t token_match(struct token_t* t,char* s,char* exp)
{
char tmp;
regmatch_t p;

tmp=s[t->stop];
s[t->stop]='\0';
p=regfind(&s[t->start],exp);
s[t->stop]=tmp;
return p;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * regularexp match on a token t on string s
 * of expression identifyed by t1 on s1
 *
 */

HIDDEN int token_match_token(struct token_t* t,char* s,
		struct token_t *t1,char* s1)
{
char tmp;
regmatch_t p1;

if((t->tag & TOK_TAG) != (t1->tag & TOK_TAG))
	return NOT_MATCHES;

tmp=s1[t1->stop];
s1[t1->stop]='\0';
p1=token_match(t,s,&s1[t1->start]);
s1[t1->stop]=tmp;

#ifdef DEBUG_MLEX
printf("# %d : ",(t1->tag & (TOK_OPT_TAG|TOK_OPT_STR)));
printf("Comparing ");
print_token(t,s);
printf(" with ");
print_token(t1,s1);
printf(" -- %s\n",p1.begin != -1 ? "OK!" : "FAILED");
#endif

if(p1.begin != -1)
	return MATCHES;
else
	return NOT_MATCHES;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * finds a sublist of data that matches pattern
 * 
 */ 
HIDDEN unsigned int mlmatch_find(list_t *data,list_t* pattern,
		char* str,char* exp,list_t* pattern_save,list_t* stack,int len)
{
if(pattern == NULL )
	{
	clean_stack(stack);
	
	return 0;
	}
else if (pattern != NULL && data == NULL)
	{
	clean_stack(stack);
	
	return 0;
	}
else 
	{
	struct token_t* t1= (struct token_t*)data->data;
	struct token_t* t2= (struct token_t*)pattern->data;
	int rc;


	if(t2->tag & TOK_OPT_TAG || t2->tag & TOK_OPT_STR)
		{
		struct back_t * back;

		back = malloc(sizeof(struct back_t));
		MALLOC_CHECK(back);
	
		back->dust_lengths = copy_dusts(pattern_save);
		back->position_stream = data;
		back->position_expr = pattern->next;
		back->len = len;

		stack = list_push(stack,back);
		}
			
	rc = token_match_token(t1,str,t2,exp);

	if(rc == MATCHES)
		{
		if(t2->tag & TOK_OPT_TAG || t2->tag & TOK_OPT_STR)
			t2->dustlen = 1;//mark used optional
		
		return 1+mlmatch_find(data->next,pattern->next,str,exp,
			pattern_save,stack,len+1);
		}
	else
		{
		// we have no chaces if it isn't an optional tag
		// we may backtrack
		struct back_t * back;

		back = list_head(stack);
		stack = list_pop(stack);

		if(back != NULL)
			{
			list_t* position_stream = back->position_stream;
			list_t* position_expr = back->position_expr;
			int old_len = back -> len;
			
			restore_dusts(pattern_save,back->dust_lengths);
			
			//free 
			list_free(back->dust_lengths,free);
			free(back);
			
			return -(len - old_len)+
				mlmatch_find(position_stream,
					position_expr,str,exp,
					pattern_save,stack,old_len);
			}
		
		return 0;
		}
	
	}
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: result refinement ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * returns oly the 'X' of data (new list)
 *
 */
HIDDEN list_t* epurate(list_t* data,int len,list_t* dl,char* txt,
	list_t* get,char* str)
{
if( (data == NULL && get == NULL) || len == 0)
	return NULL;
else if ( dl != NULL && 
	get != NULL && 
	get->data != NULL &&
	dl->data != NULL &&
	(((struct token_t*)get->data)->tag & (TOK_OPT_TAG|TOK_OPT_STR)) && 
	*((int*)dl->data) == 0)
	{
	//skip optional tag not matched
	return epurate(data,len,dl->next,txt,get->next,str);
	}
else if( data == NULL || get == NULL)
	{
	ERROR_ABORT("internal error: len(ans) != len(get)");
	}
else
	{
	if(is_a_keep(get->data,str))
		{
		list_t* tmp;
		int start=((struct token_t*)(data->data))->start;
		int stop=((struct token_t*)(data->data))->stop;
		
		tmp = malloc(sizeof(list_t));
		MALLOC_CHECK(tmp);

		tmp->data=new_chunk(start,stop);
		tmp->next=epurate(data->next,len-1,dl,txt,get->next,str);
		
		return tmp;
		}
	else
		{
#ifdef DEBUG_MLEX
		printf("(%d)droppping ",len);
		print_token(((struct token_t*)(data->data)),txt);
		printf("\n");
#endif		

		return epurate(data->next,len-1,dl,txt,get->next,str);
		}
	}
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * selects X in the answer
 * 
 */
HIDDEN list_t* mlmatch_epurate(list_t* ans,char* txt, list_t* get,char* str)
{
if (ans == NULL)	
	return NULL;
else
	{
	list_t* tmp;
	
	tmp = malloc(sizeof(list_t));
	MALLOC_CHECK(tmp);

#ifdef DEBUG_MLEX
	printf("epuration: ");	
	list_visit(((struct answer_t *)ans->data)->dust_lengths,print_int);
#endif
	
	tmp->data=epurate(((struct answer_t *)ans->data)->start,
			((struct answer_t *)ans->data)->len,
			((struct answer_t *)ans->data)->dust_lengths,
			txt,get,str);
	
	tmp->next=mlmatch_epurate(ans->next,txt,get,str);
	return tmp;
	}
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: result handling ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * returns an element
 *
 */
HIDDEN struct chunk_t* mlmatch_get_x(list_t* l,int pos)
{
if(l != NULL)
	{
	if(pos == 0)
		return ((struct chunk_t*)l->data);
	else
		return mlmatch_get_x(l->next,pos-1);
	}
else
	{
	DBG("you are asking for %d\n",pos);
	ERROR_PRINT("Internal: wrong position\n");
	return NULL;
	}

	
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * returns a row
 *
 */
HIDDEN list_t* mlmatch_get_y(list_t* l,int pos)
{
if(l != NULL)
	{
	if(pos == 0)
		return ((list_t*)l->data);
	else
		return mlmatch_get_y(l->next,pos-1);
	}
else
	{
	DBG("you are asking for %d\n",pos);
	ERROR_PRINT("Internal: wrong position\n");
	return NULL;
	}
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * strdups str[c]
 * 
 */
HIDDEN char *mlmatch_get(struct chunk_t*c,char* str)
{
char tmp;
char *rc;
tmp = str[c->stop];
str[c->stop]='\0';
rc = strdup(&str[c->start]);
MALLOC_CHECK(rc);
str[c->stop]=tmp;
return rc;
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: aux ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * helper for recursion
 *
 */
HIDDEN void mlmatch_print_results_aux(list_t*res,char* str)
{
if(res != NULL)
	{
	print_chunk((struct chunk_t*)(res->data),str);
	if(res->next != NULL)
		printf(",");
	mlmatch_print_results_aux(res->next,str);
	}
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * helper for recursion
 *
 */ 
HIDDEN list_t* mlmatch_aux(list_t *data,list_t* pattern,char* str,char* exp, 
	int min_len)
{
if (data==NULL)
	return NULL;
else
	{
	int rc;
	rc = mlmatch_find(data,pattern,str,exp,pattern,NULL,0);

	//FIX may be faster if not recalculated each time
	if(rc >= min_len) 
		{
		list_t* tmp;
		tmp = malloc(sizeof(list_t));
		MALLOC_CHECK(tmp);
		
		tmp->data=new_answer(data,rc,pattern);
		MALLOC_CHECK(tmp->data);
		tmp->next=(mlmatch_aux(data->next,pattern,str,exp,min_len));

		reset_dustlen(pattern);
		return tmp;
		}
	else
		{
		reset_dustlen(pattern);
		return mlmatch_aux(data->next,pattern,str,exp,min_len);
		}
	}
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * to restore old status in backtracking
 * 
 */ 
HIDDEN void restore_dusts(list_t* orig, list_t* copy)
{
if(orig != NULL && copy != NULL)
	{
	if (((struct token_t*)orig->data)->tag & (TOK_OPT_TAG|TOK_OPT_STR))
		{
		((struct token_t *)orig->data)->dustlen = 
			*((int *)copy->data);
		restore_dusts(orig->next,copy->next);
		}
	else
		restore_dusts(orig->next,copy);
	}
	
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * save status for backtrack
 * 
 */ 
HIDDEN list_t * copy_dusts(list_t *orig)
{
if (orig==NULL) 
	return NULL;
else if (((struct token_t*)orig->data)->tag & (TOK_OPT_TAG|TOK_OPT_STR))
	{
	list_t* tmp;
	tmp = malloc(sizeof(list_t));
	tmp->data = new_int(((struct token_t *)orig->data)->dustlen);
	tmp->next = copy_dusts(orig->next);
	return tmp;
	}
else
	return copy_dusts(orig->next);
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * clear the stack
 * 
 */ 
HIDDEN void clean_stack(list_t* stack)
{
if(stack != NULL)
	{
	struct back_t* back = list_head(stack);
	list_free(back->dust_lengths,free);
	free(back);
	clean_stack(list_pop(stack));
	}
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * sets all to 0
 *
 */ 
HIDDEN void reset_dustlen(list_t* pattern)
{
if(pattern != NULL)
	{
	((struct token_t*)pattern->data)->dustlen = 0;
	reset_dustlen(pattern->next);
	}
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * counts non optional tags in a expr
 *
 */ 
HIDDEN int exp_min_len(list_t* l)
{
if(l==NULL)
	return 0;
else
	{
	if(((struct token_t*)l->data)->tag & (TOK_OPT_TAG|TOK_OPT_STR))
		return exp_min_len(l->next);
	else
		return 1+exp_min_len(l->next);
	}
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: free ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * free answer_t
 *
 */
HIDDEN void free_answer(void *f)
{
list_free(((struct answer_t *)f)->dust_lengths,free);
free(f);
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * helper
 *
 */
HIDDEN void free_sublist(void* l)
{
list_free((list_t*)l,free);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: new ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * creates a new chunk_t
 *
 */
HIDDEN struct chunk_t * new_chunk(int start, 
		int stop)
{
struct chunk_t * tmp;

tmp = malloc(sizeof(struct chunk_t));
MALLOC_CHECK(tmp);

tmp->start=start;
tmp->stop=stop;

return tmp;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * creates a new token
 *
 */ 
HIDDEN struct token_t *new_token(int start,int stop,short tags)
{
struct token_t *tmp;

tmp = (struct token_t *)malloc(sizeof(struct token_t));
MALLOC_CHECK(tmp);

tmp->start = start;
tmp->stop = stop;
tmp->tag = tags;
tmp->dustlen=0;

return tmp;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * builds a new int 
 *
 */ 
HIDDEN void * new_int(int i)
{
int * x;
x = malloc(sizeof(int));
MALLOC_CHECK(x);
*x = i;
return x;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * builds a new dustlen list 
 *
 */ 
HIDDEN list_t* new_dust_lengths(list_t* exp)
{
if(exp == NULL)
	return NULL;
else
	{
	if( ((struct token_t*)exp->data)->tag & (TOK_OPT_TAG|TOK_OPT_STR))
		{
		list_t* tmp = malloc(sizeof(list_t));
		MALLOC_CHECK(tmp);
		
		tmp->data = new_int(((struct token_t*)exp->data)->dustlen);
		MALLOC_CHECK(tmp->data);
		
		((struct token_t*)exp->data)->dustlen=0;
		tmp->next=new_dust_lengths(exp->next);
		
		return tmp;
		}
	else
		return new_dust_lengths(exp->next);
	}
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * builds a new answer 
 *
 */
HIDDEN struct answer_t* new_answer(list_t* start,int len,list_t* exp)
{
struct answer_t*tmp;

tmp = malloc(sizeof(struct answer_t));
MALLOC_CHECK(tmp);

tmp->start=start;
tmp->len=len;
tmp->dust_lengths = new_dust_lengths(exp);

#ifdef DEBUG_MLEX
printf("-- a new answer of len %d\n",len);
list_visit(tmp->dust_lengths,print_int);
printf("\n");
#endif

return tmp;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: print ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * prints an int 
 *
 */
#ifdef DEBUG_MLEX
HIDDEN void print_int(void*x)
{
printf("%d,",*(int*)x);
}
#endif 

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * prints a token c on s
 *
 */
HIDDEN void print_token(struct token_t *c, char *s)
{
char tmp;
tmp = s[c->stop];
s[c->stop]='\0';
if(c->tag & TOK_OPT_TAG)
	{
	if(c->dustlen != 0)
		printf("{%s}*",&s[c->start]);
	else
		printf("{%s}",&s[c->start]);
	}
else if(c->tag & TOK_OPT_STR)
	{
	if(c->dustlen != 0)
		printf("[%s]*%d",&s[c->start],c->dustlen);
	else
		printf("[%s]",&s[c->start]);
	}
else if(c->tag & TOK_TAG)	
	printf("<%s>",&s[c->start]);
else
	printf("'%s'",&s[c->start]);

s[c->stop]=tmp;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * prints the whole list
 *
 */
HIDDEN void print_toklist(list_t*l, char *s, int i)
{
if(l != NULL)
	{
	print_token((struct token_t *)l->data,s);
	if(l->next != NULL)
		printf(" (%d),",i);
	print_toklist(l->next,s,i+1);
	}
else
	printf("\n\n");
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * prints first n elements only
 *
 */
HIDDEN void print_toklistn(list_t*l, char *s,int n)
{
if(l != NULL && n != 0)
	{
	print_token((struct token_t *)l->data,s);
	if(l->next != NULL && n!= 1)
		printf(",");
	print_toklistn(l->next,s,n-1);
	}
else
	printf("\n\n");
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * the answer list
 * 
 */ 
HIDDEN void print_anslist(list_t *a,char* str)
{
if (a != NULL)
	{
	print_toklistn(((struct answer_t*)a->data)->start,str,
		((struct answer_t*)a->data)->len);
	print_anslist(a->next,str);
	}
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * prints str[c]
 *
 */
HIDDEN void print_chunk(struct chunk_t*c, char* str)
{
char tmp;
tmp = str[c->stop];
str[c->stop]='\0';
printf("'%s'",&str[c->start]);
str[c->stop]=tmp;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// section: exported ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * return a strdup of res[x,y]
 */
char* mlmatch_get_result(int x,
		int y,list_t* res,char* s)
{
struct chunk_t* tmp = mlmatch_get_x(mlmatch_get_y(res,y),x);

if(tmp == NULL)
	{
	DBG("you are asking for %d %d here :\n",x,y);
	mlmatch_print_results(res,s);
	ERROR_ABORT("FIX ME");
	}
	
return mlmatch_get(tmp,s);
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * see the documentation in the .h
 *
 */ 
list_t* mlmatch(char* str, char* exp, char* get)
{
list_t * l = NULL;
list_t * r = NULL;
list_t * a = NULL;
list_t * g = NULL;
list_t * x = NULL;
int len_g,len_r,min_len_g,min_len_r;

l=tokenize_html(str);
r=tokenize_exp(exp);
g=tokenize_exp(get);

#ifdef DEBUG_MLEX
printf("print STRING\n");
print_toklist(l,str,0);
printf("print EXPRESSION\n");
print_toklist(r,exp,0);
printf("print GET\n");
print_toklist(g,get,0);
printf("print FILE\n");
printf("%s",str);
printf("\n");
#endif

len_g = list_len(g);
len_r = list_len(r);
min_len_g = exp_min_len(g);
min_len_r = exp_min_len(r);

//check for wrong args
if(len_g != len_r)
	{
	DBG("Internal: len(exp)=%d != len(get)=%d",
		len_r,len_g);
	ERROR_ABORT("list_len(g) != list_len(r)\n");
	}
if(min_len_g != min_len_r)
	{
	DBG("Internal: min_len(exp)=%d != min_len(get)=%d",
		min_len_r,min_len_g);
	ERROR_ABORT("exp_min_len(g) != exp_min_len(r)\n");
	}

//check for ambiguous matches
if ( len_g > 2 * min_len_g )
	{
	DBG("Internal: ambiguous match, too many optional tags\n");
	DBG("Internal: concrete tags are %d, while optionals are %d\n",
		min_len_g,len_g);
	}

a = mlmatch_aux(l,r,str,exp,min_len_r);

#ifdef DEBUG_MLEX
printf("print ANSWERS\n");
print_anslist(a,str);
printf("\n");
#endif

x = mlmatch_epurate(a,str,g,get);

list_free(l,free);
list_free(r,free);
list_free(g,free);
list_free(a,free_answer);

return x;
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * debug function
 *
 */
void mlmatch_print_results(list_t*res,char* str)
{
if(res != NULL)
	{
	printf("{");
	mlmatch_print_results_aux((list_t*)res->data,str);
	printf("}\n");
	mlmatch_print_results(res->next,str);
	}
}

/***  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  **
 * freedom!! 
 *
 */
void mlmatch_free_results(list_t*res)
{
list_free(res,free_sublist);
}

/* eof */
