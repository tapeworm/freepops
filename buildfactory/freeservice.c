// non parte il filgio !!!! XXX

#include <windows.h>
#include <tchar.h>
#include <stdio.h>

/* *** ERR *** */

#define die() die2(__LINE__)

static void die2(int line){
	LPVOID lpMsgBuf = NULL;
	DWORD dw = GetLastError();
   	
	FormatMessage(
   	 	FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		NULL, dw, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
	        (LPTSTR) &lpMsgBuf, 0, NULL );

	fprintf(stderr,"%d:%s\n",line,(char*)lpMsgBuf);
	LocalFree(lpMsgBuf);
	ExitProcess(dw);
}
STARTUPINFO StartupInfo;
PROCESS_INFORMATION ProcessInformation;

void start_son(DWORD argc, TCHAR* argv[]){
BOOL rc;
LPCTSTR lpApplicationName = TEXT("freepopsd.exe");
LPTSTR lpCommandLine = TEXT("freepopsd.exe --no-icon");
LPSECURITY_ATTRIBUTES lpProcessAttributes = NULL;
LPSECURITY_ATTRIBUTES lpThreadAttributes = NULL;
BOOL bInheritHandles = FALSE;
DWORD dwCreationFlags = CREATE_DEFAULT_ERROR_MODE;
LPVOID lpEnvironment = NULL;
LPCTSTR lpCurrentDirectory = NULL;

ZeroMemory( &StartupInfo, sizeof(StartupInfo) );
StartupInfo.cb = sizeof(StartupInfo);
ZeroMemory( &ProcessInformation, sizeof(ProcessInformation) );	

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

if ( !rc )
		die();

}

void kill_son(){
BOOL rc = TerminateProcess(ProcessInformation.hProcess,0);
if ( !rc )
		die();

CloseHandle(ProcessInformation.hProcess);
CloseHandle(ProcessInformation.hThread);
}

TCHAR* service_name = NULL;

SERVICE_STATUS service_status;
SERVICE_STATUS_HANDLE service_status_handle = 0;
HANDLE stop_service_event = NULL;

void service_control_handler( DWORD controlCode )
{
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
		kill_son();
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

void run_service() {

SERVICE_TABLE_ENTRY service_table[] = {
	{ (LPTSTR)service_name, (LPSERVICE_MAIN_FUNCTION)service_main },
	{ NULL, NULL }};

StartServiceCtrlDispatcher( service_table );

}

void install_service() {
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
		if ( service != NULL)
			CloseServiceHandle( service );
		else 
			die();
	} else {
		die();
	}

	CloseServiceHandle( service_control_manager );
} else {
	die();
}
}

void uninstall_service()
{
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

/* *** MAIN ** */
int _tmain( int argc, TCHAR* argv[] ) {

service_name = TEXT("FreePOPs");
	
if ( argc > 1 && lstrcmpi( argv[1], TEXT("install") ) == 0 ) {
	install_service();
} else if ( argc > 1 && lstrcmpi( argv[1], TEXT("uninstall") ) == 0 ) {
	uninstall_service();
} else {
	run_service();
}

return EXIT_SUCCESS;
}
