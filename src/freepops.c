/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://freepops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	The main function is here
 * Notes:
 * 	Options --kill added by Stefano Falsetto <falsetto@gnu.org>
 *
 * Authors:
 * 	Alessio Caprari <alessio.caprari@tiscali.it>
 * 	Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 ******************************************************************************/

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <curl/curl.h>

#if !(defined(WIN32) && !defined(CYGWIN)) // && !defined(BEOS)
	#include <sys/types.h>
	#include <sys/stat.h>
	#include <netinet/in.h>
	#include <arpa/inet.h>
	#include <netdb.h>
	#include <signal.h>
	#include <grp.h>
	#include <pwd.h>
	#include <errno.h>
#endif

#if defined(WIN32) && !defined(CYGWIN)
	#include <winsock.h>
	#include "winsystray.h"
#endif

#ifdef MACOSX
	#include "getopt1.h"
#else
	#include <getopt.h>
#endif

#ifdef HAVE_CONFIG_H
#      include "config.h"
#endif

#include "popserver.h"
#include "engine.h"
#include "altsocklib.h"
#include "regularexp.h"

#include "lua.h"
#include "luay.h"
#include "luabox.h"

#include "log.h"
#define LOG_ZONE "INTERNAL"

#include "pid.h"

#define HIDDEN static

/*** typedefs *****************************************************************/
typedef void (*sighandler_t)(int);

/*** globals setted trough command line options *******************************/

int verbose_output=0;
int daemonize = 0;
char *configfile = NULL;
char *logfile = NULL;
#if !(defined(WIN32) && !defined(CYGWIN)) && !defined(BEOS)
uid_t uid;
gid_t gid; 
#endif

/*** usage ********************************************************************/
#define GETOPT_STRING "b:p:P:A:c:u:t:l:s:dhVvwkx:"
HIDDEN  struct option opts[] = { { "bind", required_argument, NULL, 'b' },
				 { "port", required_argument, NULL, 'p' },
				 { "proxy", required_argument, NULL, 'P' },
				 { "auth", required_argument, NULL, 'A' },
				 { "useragent", required_argument, NULL, 'u' },
				 { "config", required_argument, NULL, 'c' },
				 { "threads", required_argument, NULL, 't' },
				 { "help" , no_argument , NULL, 'h'},
				 { "version" , no_argument , NULL , 'V'},
				 { "verbose", no_argument, NULL, 'v' },
				 { "veryverbose", no_argument, NULL, 'w' },
				 { "logmode", required_argument, NULL, 'l' },
				 { "daemonize", no_argument, NULL, 'd' },
				 { "suid", required_argument, NULL, 's' },
				 { "kill", no_argument, NULL, 'k' },
				 { "toxml", required_argument, NULL, 'x' },
				 { "force-proxy-auth-type", 
					 required_argument, NULL, 1000 },
				 { "fpat", 
					 required_argument, NULL, 1000 },
				 { "no-icon",no_argument, NULL, 1001},
	                         { NULL, 0, NULL, 0 } };

void usage(const char *progname) {
	fprintf(stderr, 
"Usage:  %s\t[-b|--bind address] \n"
"\t\t\t[-p|--port portnumber] \n"
"\t\t\t[-P|--proxy proxyaddress:proxyport] \n"
"\t\t\t[-A|--auth username:password] \n"
"\t\t\t[-c|--config configfile] \n"
"\t\t\t[-u|--useragent useragent] \n"
"\t\t\t[-v|--verbose [-v| --verbose]]\n"
"\t\t\t[-w|--veryverbose]\n"
"\t\t\t[-t|--threads num]\n"
"\t\t\t[-d|--daemonize]\n"
"\t\t\t[-l|--logmode (syslog|filename|stdout)]\n"
"\t\t\t[-x|--toxml pluginfile]\n"
"\t\t\t[--fpat|--force-proxy-auth-type (basic|digest|ntlm|gss)]\n"
#if defined(WIN32)
"\t\t\t[--no-icon]\n"
#endif
#if !defined(WIN32) && !defined(BEOS)			
"\t\t\t[-s|--suid user.group]\n"
"\t\t\t[-k|--kill]\n"
#endif
"        %s\t[-V|--version]\n"
"        %s\t[-h|--help]\n\n", progname, progname, progname);
}

/*** WIN32 only functions *****************************************************/
#if defined(WIN32) && !defined(CYGWIN)

void win32_init(int *argc,char ***argv,LPSTR lpszCmdLine)
{
if(stderr != freopen("stderr.txt","w",stderr)) 
	fprintf(stderr,"Unable to redirect stderr\n");

if(stdout != freopen("stdout.txt","w",stdout)) 
	fprintf(stderr,"Unable to redirect stdout\n");		
*argc = parse_commandline(argv, lpszCmdLine);
sockinit();
}

void win32_exit()
{
fclose(stdout);
fclose(stderr);
}
#endif

/*** unix only functions ******************************************************/
#if !(defined(WIN32) && !defined(CYGWIN)) && !defined(BEOS)
int *sighandler(int sig)
{
	if (sig == SIGINT || sig == SIGTERM) {
		remove_pid_file();
		SAY("%s killed by %d\n\n",PROGRAMNAME,sig);
		LOG_END();
		exit(0);
	} else {
		SAY("what?\n");
	}

	return 0;
}

void daemonize_process()
{
if(fork()!=0)
	{
	exit(0);
	}

setsid();

setpgid(0, 0);

close(0);
if(logfile != NULL && !strcmp(logfile,"stdout") && verbose_output != 0)
	{
	SAY("Can't log to %s and daemonize!\n",logfile);
	ERROR_ABORT("Bailing out!\n");
	}
close(1);
close(2);
}

int loose_rights(uid_t set_uid,gid_t set_gid)
{
int rc=0;

rc = setegid(set_gid);
if(rc == -1)
	{
	SAY("Unable to setegid(%d)",set_gid);
	return 1;	
	}

rc = seteuid(set_uid);
if(rc == -1)
	{
	SAY("Unable to seteuid(%d)",set_uid);
	return 1;	
	}

rc = setregid(getegid(),getegid());
if(rc == -1)
	{
	SAY("Unable to setregid(%d)",getegid(),getegid());
	return 1;	
	}

rc = setreuid(geteuid(),geteuid());
if(rc == -1)
	{
	SAY("Unable to setreuid(%d,%d)",geteuid(),geteuid());
	return 1;	
	}

return rc;
}

void set_signals()
{
// signal for ctrl+c 	
signal(SIGINT,  (sighandler_t) sighandler);
// signal for debian start-stop-daemon
signal(SIGTERM, (sighandler_t) sighandler);

//probably needed only by MACOSX and FreeBSD systems
signal(SIGPIPE,SIG_IGN);
}

void parse_suid(const char* optarg)
{
int rc;

if(optarg == NULL)
	fprintf(stderr,"%s : %s : %d : optarg cant be NULL\n"
		,__FILE__,__FUNCTION__,__LINE__);

//fprintf(stderr,"optarg = ^%s$\n",optarg);

if( (rc = regfind_start(optarg,"^[A-Za-z_]+\\.[A-Za-z_]+$")) != -1 )
	{
	//alphabetic form
	struct passwd *pw;
	struct group *gr;
	char *tmp = strdup(optarg);

	rc = regfind_end(tmp,"^[A-Za-z_]+\\.");
	rc--;

	tmp[rc] = '\0';
	pw = getpwnam(tmp);
	if(pw == NULL)
		{
		fprintf(stderr,"Unable to getpwnam(\"%s\")\n",tmp);
		goto error;
		}
	uid = pw->pw_uid;

	rc++;
	gr = getgrnam(&tmp[rc]);
	if(gr == NULL)
		{
		fprintf(stderr,"Unable to getgrnam(\"%s\")\n",&tmp[rc]);
		goto error;
		}
	gid = gr->gr_gid;

	//fprintf(stderr,"uid = %d gid = %d\n",uid,gid);
	
	free(tmp);
	}
else if ( (rc = regfind_start(optarg,"^[0-9]+\\.[0-9]+$")) != -1 )
	{
	//numeric form
	char *tmp = strdup(optarg);

	rc = regfind_end(tmp,"^[0-9]+\\.");
	rc--;

	tmp[rc] = '\0';
	uid = strtol(tmp,NULL,10);
	if(errno == ERANGE)
		goto error;			
	//printf("-> ^%s$\n",tmp);

	rc++;
	gid = strtol(&tmp[rc],NULL,10);
	if(errno == ERANGE)
		goto error;	
	//printf("-> ^%s$\n",&tmp[rc]);
	
	//fprintf(stderr,"uid = %d gid = %d\n",uid,gid);
	
	free(tmp);	
	}
else
	goto error;

return;

error:
	fprintf(stderr,"Invalid parameter for -s --suid.\n");
	fprintf(stderr,"usage: -s username.group\n");
	perror("bailing out");
	exit(1);	

}

#endif


/*** helpers ******************************************************************/
void start_logging(char* logfile,int verbosity)
{
log_set_verbosity(verbosity);
LOG_INIT(logfile,verbose_output == 1);
SAY("freepops started with loglevel %d on a %s machine.\n",verbosity,
	((unsigned short)1 != htons(1))?"little endian":"big endian");
}

void my_putenv(const char* a, const char* b)
{
char * tmp = calloc(1024,sizeof(char));

if(b == NULL)
	return;

snprintf(tmp,1024,"%s=%s",a,b);

/* on some system this is not a proper leak since tmp is used (not copyed)
 * in the environment.
 *
 * valgrind says this is the correct thing to do, so I prefer calling this
 * memory leak function only in the main, outside loops. so, even memory is
 * "lost" it is not a memory leak.
 */
putenv(tmp);
}

static int generate_xml(char* filename) {
char username[] = "foo@plugins2xml.lua";
lua_State* l;
start_logging(strdup(LOGFILE),0);
l = luabox_genbox(LUABOX_FULL);
bootstrap(NULL,l,username,1);

#ifdef WIN32
	{
	int len = strlen(filename) + 5;
	char *outname = calloc(len,sizeof(char));
	if ( outname == NULL) {
		fprintf(stderr,"Unable to malloc\n");
	}
	
	snprintf(outname,len,"%s.xml",filename);
	if(stdout != freopen(outname,"w",stdout)) 
		fprintf(stderr,"Unable to redirect stdout to %s\n",outname);	
	}
#endif

luay_call(l,"s","plugins2xml.main",filename);
lua_close(l);

#ifdef WIN32
fclose(stdout);
#endif

return 0;
}

/*** THE MAIN HAS YOU *********************************************************/

#if !(defined(WIN32) && !defined(CYGWIN))
int main(int argc, char *argv[]) {
#else
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    LPSTR lpszCmdLine, int nCmdShow){
#endif
	int res;
	int threads_num = MAXTHREADS;
	unsigned short port = POP3PORT;
	struct in_addr address;
	char *useragent = NULL, *proxy = NULL, *proxyauth = NULL, *fpat = NULL;

#if defined(WIN32)	
	int tray_icon = 1;
#endif

#if !(defined(WIN32) && !defined(CYGWIN)) && !defined(BEOS)	
        pid_t this_pid;
#endif

#if defined(WIN32) && !defined(CYGWIN)
	int argc;
	char **argv;

	win32_init(&argc,&argv,lpszCmdLine);
#endif

	curl_global_init(CURL_GLOBAL_ALL);
	
#if !(defined(WIN32) && !defined(CYGWIN)) && !defined(BEOS)	
	uid = geteuid();
	gid = getegid();
#endif

	address.s_addr = htonl(BINDADDRESS);
	logfile = strdup(LOGFILE); //means stdout
	
/*** ARGUMENTS PARSING ***/
	while (
	(res=getopt_long(argc,argv,GETOPT_STRING,opts,NULL))!= -1){
		if (res == 'p') {
			/* --port */
#if defined(MACOSX)
			/* ignore .app parameter */
			if (strncmp(optarg, "sn_", 3))
			{
#endif
			if ((port = atoi(optarg)) == 0) {
				fprintf(stderr, "Invalid port number\n");
				usage(argv[0]);
				exit(1);
			}
#if defined(MACOSX)
			}
#endif
		} else if (res == 'b') {
			/* --bind */
			struct hostent *host;
			
			host = gethostbyname(optarg);
			if (host == NULL) {
				usage(argv[0]);
				exit(1);
			} else {
				address = *(struct in_addr*)(host->h_addr);
			}
		} else if (res == 'P') {
			/* --proxy */
			if (proxy != NULL) {
				usage(argv[0]);
				exit(1);
			}
			proxy = strdup(optarg);
		} else if (res == 'A') {
			/* --auth */
			if (proxyauth != NULL) {
				//usage(argv[0]);
				
				exit(1);
			}
			proxyauth = strdup(optarg);
		} else if (res == 'c') {
			/* --config */
			if (configfile != NULL) {
				usage(argv[0]);
				exit(1);
			}
			configfile = strdup(optarg);
		} else if (res == 'u') {
			/* --useragent */
			if (useragent != NULL) {
				usage(argv[0]);
				exit(1);
			}
			useragent = strdup(optarg);
		} else if (res == 't'){
			/*--threads */
			if ((threads_num = atoi(optarg)) == 0) {
				fprintf(stderr, 
					"Invalid max-threads-number number\n");
				usage(argv[0]);
				exit(1);
			}
		} else if (res == 'V') {
			/* --version */
			fprintf(stderr, "%s %s\n",
				PROGRAMNAME,VERSION);
			return 0;
		} else if (res == 'h') {	
			/* --help */
			usage(argv[0]);
			return 0;
		} else if (res == 'v') {
			/* --verbose */
			verbose_output++;
		} else if (res == 'l') {
			/* --logmode */
			free(logfile);
			if ((optarg != NULL) && (optarg[0] == '-'))
				fprintf(stderr, "Warning: using %s as logfile"
					" name, which is probably not what"
					" you want.\n", optarg);
			logfile = strdup(optarg);
		} else if (res == 'd') {
			/* --daemonize */
			daemonize = 1;
			free(logfile);
			logfile = NULL; 
		} else if (res == 'x') {
			/* toxml */
			exit(generate_xml(optarg));
		} else if (res == 'w') {
			/* --veryverbose */
			verbose_output+=2;
	#if defined(WIN32)
		} else if (res == 1001) {
			tray_icon = 0;		
	#endif
		} else if (res == 1000) {
			/* --fpat */
			free(fpat);
			
			if (optarg != NULL)
				fpat = strdup(optarg);
			else
				fprintf(stderr,"fpat has NULL arg");
			
			if ( strcmp(fpat,"gss") && 
			     strcmp(fpat,"ntlm") &&
			     strcmp(fpat,"basic") && 
			     strcmp(fpat,"digest") ) {
				fprintf(stderr, "--fpath accepts only one of"
					"these: gss, ntlm, basic, digest\n\n");
				usage(argv[0]);
				exit(1);
			}
	#if !(defined(WIN32) && !defined(CYGWIN)) && !defined(BEOS)
		} else if (res == 'k') {
			/* --kill */
			/* Kill freepopsd with pid contained in .pid file */
			this_pid = retrieve_pid_file(PIDFILE);
			if (this_pid != PIDERROR) {
				kill((pid_t)this_pid, SIGINT);
                                exit(0);
                        } else {
				printf("Warning: can't find a pid file.\n");
				exit(1);
			}
		} else if (res == 's') {
			/* --suid */
			parse_suid(optarg);
	#endif			
		} else {
			usage(argv[0]);
			exit(1);
		}
	}
	
/*** INITIALIZATION ALL ***/
	
	srand(time(NULL) + getpid());
	
	start_logging(logfile,verbose_output);
	
	if(useragent == NULL)
		useragent = strdup(DEFAULT_USERAGENT);
	
	my_putenv("LUA_HTTP_USERAGENT",useragent);
	my_putenv("LUA_HTTP_PROXY",proxy);
	my_putenv("LUA_HTTP_PROXYAUTH",proxyauth);
	my_putenv("LUA_FORCE_PROXY_AUTH_TYPE",fpat);
	
/*** INITIALIZATION UNIX ***/
#if !(defined(WIN32) && !defined(CYGWIN)) && ! defined(BEOS)
	if(daemonize)
		daemonize_process();
	
	create_pid_file(PIDFILE);
	
	set_signals();
#endif

/*** INITIALIZATION WIN32 ***/
#if defined(WIN32) && !defined(CYGWIN)
	if(tray_icon)
		create_tray_icon(hInstance,hPrevInstance,lpszCmdLine,nCmdShow);
#endif

/*** GO! ***/
#if !(defined(WIN32) && !defined(CYGWIN)) && ! defined(BEOS)
	popserver_start(&freepops_functions, address, port, threads_num,
		loose_rights,uid,gid);
#else
	popserver_start(&freepops_functions, address, port, threads_num,
		NULL,0,0);
#endif
	
/*** EXIT ***/
#if defined(WIN32) && !defined(CYGWIN)
	win32_exit();
#endif

	return EXIT_SUCCESS;
}


