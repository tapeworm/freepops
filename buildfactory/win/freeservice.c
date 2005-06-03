/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://www.freepops.org)                     *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	FreePOPs Win32 service daemon
 * Notes:
 *	really inspired by http://www.muukka.net/programming/service.html
 * Authors:
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <windows.h>
#include <tchar.h>
#include <stdio.h>
#include <direct.h>

#include "winregistry.h"

#define FP_BIN "freepopsd.exe"
#define FP_DEFAULT_ARG "--no-icon"
#define FP_DESC "FreePOPs daemon service. http://www.freepops.org"

#define FP_NSIS_BASE "SOFTWARE\\NSIS_FreePOPs"
#define FP_NSIS_INSTDIR "Install_Dir"

#define FP_SERVICE_BASE "SOFTWARE\\NSIS_FreePOPs"
#define FP_SERVICE_CL "Command_Line"

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** globals *** */

STARTUPINFO StartupInfo;
PROCESS_INFORMATION ProcessInformation;
TCHAR* service_name = NULL;
SERVICE_STATUS service_status;
SERVICE_STATUS_HANDLE service_status_handle = 0;
HANDLE stop_service_event = NULL;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** error print *** */

#define die() die2(__LINE__)

static void die2(int line){
	LPVOID lpMsgBuf = NULL;
	DWORD dw = GetLastError();
   	
	FormatMessage(
   	 	FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		NULL, dw, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
	        (LPTSTR) &lpMsgBuf, 0, NULL );

	fprintf(stderr,"ERROR %d : %s\n",line,(char*)lpMsgBuf);
	LocalFree(lpMsgBuf);
	ExitProcess(dw);
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** argv mangling *** */
char * argv2str(int argc,char* argv[]){

int i,len;
char* lpCommandLine;

len = strlen(FP_DEFAULT_ARG) + 1 + strlen(FP_BIN) + 1 + 2;
for (i = 0 ; i < argc; i++) {
	len += strlen(argv[i]) + 1;	
}

lpCommandLine = calloc(len,sizeof(char));
if(lpCommandLine == NULL)
	die();

sprintf(lpCommandLine,"%s %s ",FP_BIN,FP_DEFAULT_ARG);
for (i = 0 ; i < argc; i++) {
	strcat(lpCommandLine,argv[i]);	
	strcat(lpCommandLine," ");
}

return lpCommandLine;
}


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** start and kill son *** */

void start_son(DWORD argc, TCHAR* argv[]){
BOOL rc;
LPTSTR lpApplicationName = NULL;
LPTSTR lpCommandLine = NULL;
LPSECURITY_ATTRIBUTES lpProcessAttributes = NULL;
LPSECURITY_ATTRIBUTES lpThreadAttributes = NULL;
BOOL bInheritHandles = FALSE;
DWORD dwCreationFlags = CREATE_DEFAULT_ERROR_MODE;
LPVOID lpEnvironment = NULL;
LPCTSTR lpCurrentDirectory = NULL;
int len;

// retrive installation dir
get_key_value_as(HKEY_LOCAL_MACHINE,FP_NSIS_BASE,
	string_marshal,FP_NSIS_INSTDIR,&lpCurrentDirectory);

if(lpCurrentDirectory == NULL)
	die();

// build file name with full path
len = 2 + strlen(FP_BIN) + strlen(lpCurrentDirectory);
lpApplicationName = calloc(len,sizeof(char));
if( lpApplicationName == NULL)
	die();
snprintf(lpApplicationName,len,"%s\\%s",lpCurrentDirectory,FP_BIN);

// build command line
if (argc > 1) {
	// build the command line if passed 
	// by the user from the service control panel
	lpCommandLine = argv2str(argc-1,&argv[1]);
} else {
	//use the registry
	get_key_value_as(HKEY_LOCAL_MACHINE,"SOFTWARE\\NSIS_FreePOPs",
		string_marshal,FP_SERVICE_CL,&lpCommandLine);
	if(lpCommandLine == NULL)
		lpCommandLine = strdup(FP_DEFAULT_ARG);
}

// reset some shit
ZeroMemory( &StartupInfo, sizeof(StartupInfo) );
StartupInfo.cb = sizeof(StartupInfo);
ZeroMemory( &ProcessInformation, sizeof(ProcessInformation) );	

// full the stack with parameters
rc = CreateProcess(
   lpApplicationName,
   lpCommandLine,
   lpProcessAttributes,
   lpThreadAttributes,
   bInheritHandles,
   dwCreationFlags,
   lpEnvironment,
   lpCurrentDirectory,
   &StartupInfo,
   &ProcessInformation);

if ( rc == 0 )
	die();
}


void kill_son(){
BOOL rc = TerminateProcess(ProcessInformation.hProcess,0);
if ( !rc )
		die();

CloseHandle(ProcessInformation.hProcess);
CloseHandle(ProcessInformation.hThread);
}


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** signal handler *** */


void service_control_handler( DWORD controlCode ){
switch ( controlCode )
{
	case SERVICE_CONTROL_INTERROGATE:
	case SERVICE_CONTROL_PAUSE:
	case SERVICE_CONTROL_CONTINUE:
		break;

	case SERVICE_CONTROL_SHUTDOWN:
	case SERVICE_CONTROL_STOP:
		service_status.dwCurrentState = SERVICE_STOP_PENDING;
		SetServiceStatus( service_status_handle, &service_status );
		SetEvent(stop_service_event);
		return;

	default:
		if ( controlCode >= 128 && controlCode <= 255 )
			// user defined control code
			break;
		else
			// unrecognised control code
			break;
}

SetServiceStatus( service_status_handle, &service_status );
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** service main *** */

void service_main( DWORD argc, TCHAR* argv[] ) {
	
// initialise service status
service_status.dwServiceType = SERVICE_WIN32;
service_status.dwCurrentState = SERVICE_STOPPED;
service_status.dwControlsAccepted = 0;
service_status.dwWin32ExitCode = NO_ERROR;
service_status.dwServiceSpecificExitCode = NO_ERROR;
service_status.dwCheckPoint = 0;
service_status.dwWaitHint = 0;

service_status_handle = RegisterServiceCtrlHandler(service_name,
	(LPHANDLER_FUNCTION)service_control_handler);

if ( service_status_handle != 0 ) {
	DWORD wait_rc;
	
	// service is starting
	service_status.dwCurrentState = SERVICE_START_PENDING;
	SetServiceStatus( service_status_handle, &service_status );

	// do initialisation here
	stop_service_event = CreateEvent( 0, FALSE, FALSE, 0 );
	
	// running
	service_status.dwControlsAccepted |= 
		(SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN);
	service_status.dwCurrentState = SERVICE_RUNNING;
	SetServiceStatus( service_status_handle, &service_status );

	// start child process
	start_son(argc,argv);
	wait_rc = WaitForSingleObject( stop_service_event,INFINITE);
	if ( wait_rc != WAIT_OBJECT_0 )
		die();
	kill_son();

	// service was stopped
	service_status.dwCurrentState = SERVICE_STOP_PENDING;
	SetServiceStatus( service_status_handle, &service_status );

	// do cleanup here
	CloseHandle(stop_service_event);
	stop_service_event = NULL;
		
	// service is now stopped
	service_status.dwControlsAccepted &= 
		~(SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN);
	service_status.dwCurrentState = SERVICE_STOPPED;
	SetServiceStatus( service_status_handle, &service_status );
} else {
	die();
}
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** run service function *** */
void run_service() {

SERVICE_TABLE_ENTRY service_table[] = {
	{ (LPTSTR)service_name, (LPSERVICE_MAIN_FUNCTION)service_main },
	{ NULL, NULL }};

/* this never returns */
if (StartServiceCtrlDispatcher( service_table ) == 0)
	die();
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** install it *** */
void install_service(int argn, char* argv[]) {
SC_HANDLE service_control_manager = 
	OpenSCManager( 0, 0, SC_MANAGER_CREATE_SERVICE );
if ( service_control_manager != NULL ) {
	TCHAR path[ MAX_PATH + 1 ];
	if (GetModuleFileName(0,path,_MAX_PATH + 1) > 0 ) {
		SC_HANDLE service = 
			CreateService( service_control_manager,
				service_name, service_name,
				SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS,
				SERVICE_AUTO_START, SERVICE_ERROR_IGNORE, path,
				NULL, NULL, NULL, NULL, NULL);
		if ( service != NULL){
			char * tmp;
			SERVICE_DESCRIPTION desc= {
				FP_DESC
			};
			BOOL rc = ChangeServiceConfig2(service,
				SERVICE_CONFIG_DESCRIPTION,&desc);

			if( rc == 0)
				die();
			tmp = argv2str(argn,argv);
			set_key_value_as_string(HKEY_LOCAL_MACHINE,
				FP_SERVICE_BASE,
				FP_SERVICE_CL,tmp);
			free(tmp);
	
			CloseServiceHandle( service );
		} else 
			die();
	} else {
		die();
	}

	CloseServiceHandle( service_control_manager );
} else {
	die();
}
}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** remove it *** */
void uninstall_service() {

SC_HANDLE service_control_manager = OpenSCManager( 0, 0, SC_MANAGER_CONNECT );

if ( service_control_manager != NULL ) {
	SC_HANDLE service = OpenService( service_control_manager,
		service_name, SERVICE_QUERY_STATUS | DELETE );
	if ( service != NULL ) {
		SERVICE_STATUS service_status;
		if ( QueryServiceStatus( service, &service_status ) != 0) {
			if ( service_status.dwCurrentState == SERVICE_STOPPED )
				DeleteService( service );
			else
				fprintf(stderr,"Unable to uninstall."
						" Service must be stopped\n");
				die();
		}
		CloseServiceHandle( service );
	} else {
		die();
	}
	
	CloseServiceHandle( service_control_manager );
} else {
	die();	
}

}

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* *** here we are *** */
int _tmain( int argc, TCHAR* argv[] ) {

service_name = TEXT("FreePOPs");
	
if ( argc > 1 && lstrcmpi( argv[1], TEXT("install") ) == 0 ) {
	char dummy[10];
	install_service(argc - 2,&argv[2]);
	printf("\nService installed - press enter to continue...\n");
	fgets(dummy,10,stdin);
} else if ( argc > 1 && lstrcmpi( argv[1], TEXT("uninstall") ) == 0 ) {
	char dummy[10];
	uninstall_service();
	printf("\nService removed - press enter to continue...\n");
	fgets(dummy,10,stdin);
} else if ( argc == 1) {
	run_service();
} else {
	fprintf(stderr,"\nusage: %s [install [options]|uninstall]\n\n",argv[0]);
	fprintf(stderr,"Example:\n");
	fprintf(stderr,"\t%s install -w -p110\n",argv[0]);
	fprintf(stderr,"\t%s uninstall\n\n",argv[0]);
	ExitProcess(1);
}


return EXIT_SUCCESS;
}

//eof
