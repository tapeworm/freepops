/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	base64 encoding
 * Notes:
 *	
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifndef MALLOC_CHECK
#define MALLOC_CHECK(a) {if(a==NULL)abort();}
#endif

static const char table[64] =
{
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
  'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
  'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
  'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
  'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
  'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '0', '1', '2', '3',
  '4', '5', '6', '7', '8', '9', '+', '/'
};

__inline__ int get6bitsfrom(unsigned int n,int from)
{
return ((n & (0x3f << from)) >> from) ;
}

char *base64enc_raw(const char *input,size_t len)
{
int in_len;
int out_len;
char * output;
int i = 0, o = 0;

if(input == NULL)
	return NULL;

in_len = /*strlen(input);*/ len ;

if(in_len != 0)
	{
	/* out_len = (in_len / 4 + 1) * 4 + 1; */  // ???? why this formula?
	out_len = ((in_len - 1) / 3 + 1) * 4 + 1;
	output = calloc(out_len,sizeof(char));
	MALLOC_CHECK(output);
	}
else
	{
	return strdup(input);	// is standard?
	}

// printf("input is %s -> ",input);
  
while(i < in_len)
	{
	unsigned int tmp;
	int equal;
	
	tmp = 0;
	equal = 0;
		
	/*  */
	if (/*input[i + 0] != '\0'*/ i < in_len)
		tmp += (0xff &  input[i + 0]) << 16;
	else
		break;
	if (/*input[i + 1] != '\0'*/ i + 1 < in_len)
		tmp += (0xff &  input[i + 1]) << 8;
	else
		equal+=2;
	if ((!equal) && /*input[i + 2] != '\0'*/ i + 2 < in_len)
		tmp += (0xff & input[i + 2]) ;
	else
		equal+=1;

	/* fill the output */
	output[ o + 0 ] = table[get6bitsfrom(tmp,18)];
	output[ o + 1 ] = table[get6bitsfrom(tmp,12)];
	if(equal > 1)
		output[ o + 2 ] = '=';
	else
		output[ o + 2 ] = table[get6bitsfrom(tmp,6)];
	if(equal > 0)
		output[ o + 3 ] = '=';
	else
		output[ o + 3 ] = table[get6bitsfrom(tmp,0)];
	
	/* next */
	i+=3;
	o+=4;
	}

output[out_len - 1] = '\0';

return output;
}

char *base64enc(const char *input){
	return base64enc_raw(input,strlen(input));
}

static unsigned int index_in_table(char c){
	int i;
	if (c == '=') return 0;
	for(i=0;i < 64 && table[i] != c;i++) ;
	if (i == 64) {
		return -1;
	} else {
		return i;
	}
}

char *base64dec(const char *input, size_t len){
	char * rc = calloc(len * 3 / 4 + 4,sizeof(char));
	size_t i,o=0;
	MALLOC_CHECK(rc);

	for(i=0; i+3<=len; ){
		char c1 = input[i++];
		char c2 = input[i++];
		char c3 = input[i++];
		char c4 = input[i++];
		unsigned int val1 = index_in_table(c1);
		unsigned int val2 = index_in_table(c2);
		unsigned int val3 = index_in_table(c3);
		unsigned int val4 = index_in_table(c4);
		unsigned char rc1 = (val1 << 2) | (val2 >> 4);
		unsigned char rc2 = ((val2 & 15) << 4) | (val3 >> 2);
		unsigned char rc3 = ((val3 & 3) << 6) | val4;

		rc[o++] = rc1;
		if (c3 != '='){
			rc[o++] = rc2;
		}
		if (c4 != '='){
			rc[o++] = rc3;
		}
	}
	rc[o]='\0';

	return rc;
}

