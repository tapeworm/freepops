/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	gets proxy info from the registry
 * Notes:
 *	
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#ifdef WIN32

#include <windows.h>
#include <stdio.h>

#include "winregistry.h"

#define MAX_KEY_LENGTH 255
#define MAX_VALUE_NAME 16383

#define ERROR_CHECK(a) {\
	if(a != ERROR_SUCCESS)\
		{\
		int c;\
		LPVOID lpMsgBuf;\
		DWORD rc = FormatMessage(\
			FORMAT_MESSAGE_FROM_SYSTEM|\
			FORMAT_MESSAGE_ALLOCATE_BUFFER|\
			FORMAT_MESSAGE_IGNORE_INSERTS,\
			NULL,\
			(c=GetLastError()),\
			MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),\
			(LPTSTR) &lpMsgBuf,\
			0,\
			NULL);\
		if(rc != 0)\
			printf("ERROR (%s,%d) %d : %s\n",__FILE__,__LINE__,c,\
				(LPCTSTR)lpMsgBuf);\
		else\
			printf("FormatMessage failed!\n");\
		LocalFree(lpMsgBuf);\
		}\
	}


int string_marshal(char* name,void* rt,char*achValue,char*achData,int type)
{
if(!strcmp(achValue,name) && type == REG_SZ)
	{
	*(char**)rt = strdup((char*)achData);
	return 1;
	}
else
	{
	return 0;
	}
}

int int_marshal(char* name,void* rt,char*achValue,char*achData,int type)
{
if(!strcmp(achValue,name) && type == REG_DWORD)
	{
	*(int*)rt = (*(int*)achData);
	return 1;
	}
else
	{
	return 0;
	}
}

void get_key_value_as(HKEY root,const char*path,
	int(*regmarshal)(char*,void*,char*,char*,int),char*param,void* ret)
{
LONG rc;
HKEY k;
HKEY kroot;
DWORD cchValue = MAX_VALUE_NAME; 
DWORD cchData = MAX_VALUE_NAME; 
CHAR  achValue[MAX_VALUE_NAME];
CHAR  achData[MAX_VALUE_NAME];
DWORD type;
int i;

rc = RegOpenKeyEx(root,NULL,0,KEY_QUERY_VALUE,&kroot);
ERROR_CHECK(rc);

rc = RegOpenKeyEx(kroot,path,0,KEY_QUERY_VALUE,&k);
ERROR_CHECK(rc);

for(i=0;;i++)
	{
	cchValue = MAX_VALUE_NAME; 
	cchData = MAX_VALUE_NAME;
	achValue[0]='\0';
	achData[0]='\0';
	
	rc = RegEnumValue(k,i,achValue,&cchValue,NULL,&type,achData,&cchData);
	if(rc != ERROR_SUCCESS)
		break;

	if (regmarshal(param,ret,achValue,achData,type))
		break;
		
	}

rc = RegCloseKey(k);
ERROR_CHECK(rc);

rc = RegCloseKey(kroot);
ERROR_CHECK(rc);

}

void set_key_value_as_string(
	HKEY root,const char*path,const char * key, const char * val){

LONG rc;
HKEY k;
HKEY kroot;

rc = RegOpenKeyEx(root,NULL,0,KEY_SET_VALUE,&kroot);
ERROR_CHECK(rc);

rc = RegOpenKeyEx(kroot,path,0,KEY_SET_VALUE,&k);
ERROR_CHECK(rc);

//printf("setto %s a %s\n",key,val);
rc = RegSetValueEx(k,key,0,REG_SZ,val,strlen(val)+1);	
ERROR_CHECK(rc);

rc = RegCloseKey(k);
ERROR_CHECK(rc);

rc = RegCloseKey(kroot);
ERROR_CHECK(rc);
}


#endif // WIN32
