/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	tary icon
 * Notes:
 *
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include "winsystray.h"

#ifdef WIN32

#include <windows.h>
#include <windowsx.h>
#include <shellapi.h>
#include <pthread.h>
#include <winuser.h>

#include "regularexp.h"
#include "win32_resources.h"
#include "log.h"
#define LOG_ZONE "WIN"

#include "config.h"

#define HIDDEN static

//! min of two
#ifndef MIN
#define MIN(a,b) (((a)<(b))?(a):(b))
#endif

//! max of two
#ifndef MAX
#define MAX(a,b)	((a<b)?(b):(a))
#endif

/*** define *******************************************************************/

#define AP_ID 1
#define UWM_SYSTRAY (WM_USER + 1)

/*** globals ******************************************************************/

HIDDEN HINSTANCE ghInst;

HIDDEN struct 
	{
	HINSTANCE hInstance; 
	HINSTANCE hPrevInstance;
	LPSTR lpszCmdLine; 
	int nCmdShow;
	} parametri;

HIDDEN pthread_t dispatcher;
HIDDEN pthread_attr_t att;
HIDDEN int can_download_cfg;

/*** callback *****************************************************************/

/**************************
 * the real callback
 *
 */
HIDDEN int download_cfg()
{
return 0;
}

// helper function for get_news()
HIDDEN long str_to_num(char* v)
{
int a,b,c;
sscanf(v,"%d.%d.%d",&a,&b,&c);
return c + b*100 + a*10000;
}

/**************************
 * the real callback
 *
 */
HIDDEN int get_news(char **news_msg)
{
return 0;
}

/**********************
 * the real callback
 *
 */ 
HIDDEN LRESULT CALLBACK wndProc(HWND hwnd, UINT message,
	WPARAM wParam, LPARAM lParam)
{
POINT pt;
HMENU hmenu, hpopup;
NOTIFYICONDATA nid;
char *news_msg;
int news_out;

switch (message) 
	{
	case WM_CREATE:
      		return TRUE;
	break;

    	case WM_DESTROY:
		nid.cbSize = sizeof(NOTIFYICONDATA);
		nid.hWnd = hwnd;
		nid.uID = AP_ID;
		nid.uFlags = NIF_TIP; 
		Shell_NotifyIcon(NIM_DELETE, &nid);
		PostQuitMessage(0); //?
	return TRUE;

	case UWM_SYSTRAY:
      		
		switch (lParam) {
        		case WM_RBUTTONDOWN: 
        		case WM_LBUTTONDOWN: 
			
			SetCursor(LoadCursor(NULL,IDC_ARROW));
          		GetCursorPos(&pt);
			hmenu = LoadMenu(ghInst, MAKEINTRESOURCE(RES_MENU));
			hpopup = GetSubMenu(hmenu, 0);

          		SetForegroundWindow(hwnd);

			if(!can_download_cfg)
				{
				EnableMenuItem(hpopup,
					RES_MENU_DOWNLOAD,MF_GRAYED);
				//DBG("disabled\n");
				}
			else
				{
				EnableMenuItem(hpopup,
					RES_MENU_DOWNLOAD,MF_ENABLED);
				
				//DBG("enabled\n");
				}
	  
		        switch (TrackPopupMenu(hpopup, 
				TPM_RETURNCMD | TPM_RIGHTBUTTON|TPM_LEFTBUTTON,
				pt.x, pt.y, 0, hwnd, NULL)) 
	  			{
				case RES_MENU_EXIT: 
					DestroyWindow(hwnd);
					SAY("FreePOPs killed by the "
						"context menu.");
					exit(0);
				break;
				
				case RES_MENU_ABOUT:
					MessageBox(NULL, ABOUT_STRING,
					ABOUT_TITLE, MB_OK | MB_ICONINFORMATION);
				break;

				case RES_MENU_DOWNLOAD:
					if (MessageBox(NULL, DOWNLOAD_ASK,
					  DOWNLOAD_TITLE, MB_YESNO|MB_ICONQUESTION) == IDYES)
					{
					if (download_cfg() == 0)
					  MessageBox(NULL,DOWNLOAD_STRING ,
					  DOWNLOAD_TITLE, MB_OK|MB_ICONINFORMATION);
					else
					  MessageBox(NULL,DOWNLOAD_STRING_ERR ,
					  DOWNLOAD_TITLE, MB_OK|MB_ICONERROR);
					}
				break;
				
				case RES_MENU_NEWS:
					news_out = get_news(&news_msg);
					if (news_out==0)
					{
					  MessageBox(NULL, news_msg,
					  NEWS_TITLE, MB_OK|MB_ICONINFORMATION);
					  free(news_msg);
					  news_msg = NULL;
					}
					else if (news_out == 1)
					  MessageBox(NULL, NO_NEWS_STRING,
					  NEWS_TITLE, MB_OK|MB_ICONWARNING);
					else
					  MessageBox(NULL, GET_NEWS_ERROR,
					  NEWS_TITLE, MB_OK|MB_ICONERROR);
				break;
	  			}
          
	  		PostMessage(hwnd, 0, 0, 0);
			DestroyMenu(hmenu); // Delete loaded menu 
          		break;
	
		default:
	  	return TRUE;

		}
    	default:
	return TRUE; // I don't think that it matters what you return.
	}
return DefWindowProc(hwnd, message, wParam, lParam);
}

/*** creates a tray icon ******************************************************/

void tray_init(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    LPSTR lpszCmdLine, int nCmdShow)
{
HWND hwnd;
MSG msg;
WNDCLASSEX wc;
NOTIFYICONDATA nid;
char *classname = "FreePOPs.NOTIFYICONDATA.hWnd";

ghInst = hInstance;
  
/* Create a window class for the window that receives systray notifications.*/
wc.cbSize = sizeof(WNDCLASSEX);
wc.style = 0;
wc.lpfnWndProc = wndProc;
wc.cbClsExtra = wc.cbWndExtra = 0;
wc.hInstance = hInstance;
wc.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(RES_ICON_32));
wc.hCursor = LoadCursor(NULL, IDC_ARROW);
wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
wc.lpszMenuName = NULL;
wc.lpszClassName = classname;
wc.hIconSm = LoadImage(hInstance, MAKEINTRESOURCE(RES_ICON_32), IMAGE_ICON,
	GetSystemMetrics(SM_CXSMICON),GetSystemMetrics(SM_CYSMICON), 0);
  
RegisterClassEx(&wc);
  
// Create window. Note that WS_VISIBLE is not used, and window is never shown
hwnd = CreateWindowEx(0, classname, classname, WS_POPUP, CW_USEDEFAULT, 0,
	CW_USEDEFAULT, 0, NULL, NULL, hInstance, NULL);

// size
nid.cbSize = sizeof(NOTIFYICONDATA); 
// window to receive notification
nid.hWnd = hwnd; 
// application-defined ID
nid.uID = AP_ID; 
// nid.uCallbackMessage, nid.hIcon,  nid.szTip are valid, use them
nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
// message sent to nid.hWnd
nid.uCallbackMessage = UWM_SYSTRAY;
// load the icon
nid.hIcon = LoadImage(hInstance, MAKEINTRESOURCE(RES_ICON_16), IMAGE_ICON,
                        GetSystemMetrics(SM_CXSMICON),
                        GetSystemMetrics(SM_CYSMICON), 0); 
// ToolTip (64 byte)
strcpy(nid.szTip,"FreePOPs v " VERSION);

// This adds the ico
Shell_NotifyIcon(NIM_ADD, &nid); 

//??
while ( GetMessage(&msg, NULL, 0, 0)) 
	{
	TranslateMessage(&msg);
	DispatchMessage(&msg);
  	}

}

/*** the thread ***************************************************************/

HIDDEN void* thread_tray_init(void *p)
{	
tray_init(parametri.hInstance,parametri.hPrevInstance,
		parametri.lpszCmdLine,parametri.nCmdShow);
return NULL;
}

/*** the exported function ****************************************************/

void create_tray_icon(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    LPSTR lpszCmdLine, int nCmdShow)
{
parametri.hInstance = hInstance;
parametri.hPrevInstance = hPrevInstance;
parametri.lpszCmdLine = lpszCmdLine;
parametri.nCmdShow = nCmdShow;
	
pthread_attr_init(&att);
pthread_attr_setdetachstate(&att,PTHREAD_CREATE_DETACHED);

pthread_create(&dispatcher,&att,thread_tray_init,NULL);

}


int parse_commandline(char*** argv,char* arg)
{
regmatch_t p;
char *str = strdup(arg);
int position=0,n=0;
char **argv_win32;

//printf("#%s#\n",arg);

/* count args */
position=0;
do	
	{
	p = regfind(&str[position],"[^ \"]+");
	if(p.begin != -1)
		{
		if(str[MAX(position + p.begin - 1,0)] != '"')
			{
			n++;
			position+=p.end;
			}
		else
			{
			int tmp = p.begin;
			p = regfind(&str[position+tmp],"\"");
			if(p.begin != -1)
				{
				n++;
				position+=p.end+tmp;
				}
			else
				{
				ERROR_ABORT("Wrong arg string\n");
				}
			
			}
		}
	}
while(p.begin != -1);
	
argv_win32 = calloc(n+1,sizeof(char*));
MALLOC_CHECK(argv_win32);

position = 0;
n=0;
argv_win32[0]=strdup("freepopsd.exe");
n++;

do	
	{
	p = regfind(&str[position],"[^ \"]+");
	if(p.begin != -1)
		{
		if(str[MAX(position + p.begin - 1,0)] != '"')	
			{
			char tmp = str[position + p.end];
			str[position + p.end]='\0';
			argv_win32[n] = strdup(&str[position+p.begin]);
			//printf("'%s'\n",argv_win32[n]);
			str[position + p.end]=tmp;
			n++;
			position+=p.end;
			}
		else
			{
			int x = p.begin;
			p = regfind(&str[position+x],"\"");
			if(p.begin != -1)
				{
				char tmp = str[position + p.end + x - 1];
				str[position + p.end + x - 1]='\0';
				argv_win32[n] = strdup(&str[position+x]);
				//printf("'%s'\n",argv_win32[n]);
				str[position + p.end + x - 1]=tmp;
				n++;

				position+=p.end+x;
				}
			else
				{
				ERROR_ABORT("Wrong arg string\n");
				}
			}
		}
	}
while(p.begin != -1);

*argv=argv_win32;

free(str);
return n;
}

#endif

