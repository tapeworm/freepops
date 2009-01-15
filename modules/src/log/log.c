/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 * 	Implements logging function
 * Notes:
 *
 * Authors:
 * 	Simone Vellei <simone_vellei@users.sourceforge.net>
 ******************************************************************************/

#include <stdarg.h>
#include <stdio.h>
#include <time.h>
#include <sys/stat.h>
#include <errno.h>
#include <pthread.h>
#include <math.h>

#include "regularexp.h"
#include "log.h"
#define LOG_ZONE "LOG"

#define HIDDEN static

#define OPENLOG_NAME "freepopsd"
//! max of two
#ifndef MAX
#define MAX(a,b)        ((a<b)?(b):(a))
#endif
//! len
#define B(n)           floor(MAX(log10(n),0) + 1)

/******************************************************************************/

HIDDEN int verbose_output = 0;
HIDDEN FILE *fd = NULL;
HIDDEN char *log_file_name = NULL;

#ifndef WIN32
HIDDEN int do_syslog = 0;
#endif

#define ZONE_POSTPEND 	": "
#define MAX_LOG_FILE_NEMBER 100
#define LOG_OF_MAX_LOG_FILE_NEMBER_PLUS_1 4
#define LOG_FILE_FORMAT "%s.%d"

/******************************************************************************/

HIDDEN pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

HIDDEN int file_exists(char *filename) {
	
	FILE *fp;
	fp = fopen(filename,"r");

	if(fp != NULL){
		fclose(fp);
		return(1);
	}
	else
		return(0);
}

HIDDEN char *get_free_logfile(char *logfile){

	int suffix=-1;
	int len  = strlen(logfile)+LOG_OF_MAX_LOG_FILE_NEMBER_PLUS_1;
	char *str = (char*) calloc(len,sizeof(char));
	
	if (str == NULL){
		fprintf(stderr,"Out of memory allocating free log file name\n");
		exit(1);
	}
		
	do {	
		suffix++;
		memset(str,0,len);
		snprintf(str,len,LOG_FILE_FORMAT,logfile,suffix);
	} while(file_exists(str) && suffix < MAX_LOG_FILE_NEMBER);
	
	if (suffix == 100) {
		fprintf(stderr,"Unable to find a free file name\n");
		return NULL;
	}
	
	return(str);
}

HIDDEN void remove_all_old_log_files(char *logfile){
	int suffix;
	int len  = strlen(logfile)+LOG_OF_MAX_LOG_FILE_NEMBER_PLUS_1;
	char *str = (char*) calloc(len,sizeof(char));
	
	for (suffix=0;suffix<MAX_LOG_FILE_NEMBER;suffix++){
		memset(str,0,len);
		snprintf(str,len,LOG_FILE_FORMAT,logfile,suffix);
		remove(str);	
	}
	free(str);
}

HIDDEN void copy_file(char *src, char* dst){

	FILE *fpin, *fpout;

	char buf[512];
	int n;

	fpin = fopen(src,"r");
	fpout = fopen(dst,"w");

	if ( fpin == NULL || fpout == NULL) {
		fprintf(stderr,"Unable to open %s or %s\n",src,dst);
		return;
	}

	for(;;){
		n = fread(buf, 1, 512, fpin);

		if(n == 0)
			break;
		fwrite(buf, 1, n, fpout);
	}

	fclose(fpin);
	fclose(fpout);
}

// controls logfile size
int log_rotate(char *logfile)
{
	struct stat filestats;
	int rc;
	int reopen=0;

	pthread_mutex_lock(&mutex);

	if(fd!=NULL)
		reopen=1;

	rc = stat(logfile, &filestats);
	
	if (rc != -1 && filestats.st_size > MAX_LOG_SIZE) {
		char *freefile=get_free_logfile(logfile);
		
		if ( freefile == NULL) {
			//retry after removing files
			remove_all_old_log_files(logfile);
			freefile=get_free_logfile(logfile);
			
			if ( freefile == NULL) {
				fprintf(stderr,
					"Unable to open free log file\n");
				exit(1);
			}
		}
		// creates backup file
		copy_file(logfile, freefile);
		free(freefile);
		remove(logfile);
	}

	if(reopen) {
		fclose(fd);
		fd = fopen(logfile, "a");
		if (fd == NULL) {
			fprintf(stderr,"Unable to open %s\n",logfile);
			exit(1);
		}
	}
	
	pthread_mutex_unlock(&mutex);

	return 0;
}



int log_init(char* logfile)
{
#if (!(defined(WIN32) && !defined(CYGWIN))) && (!defined(BEOS))
	char *filestr = NULL;

	if(logfile == NULL)
		{
		//suppress the log!
		filestr = strdup("/dev/null");
		}
	else if (!strcmp(logfile,"stdout"))
		{
		//log to stdout		
		filestr = NULL;
		}
#ifndef WIN32
	else if (!strcmp(logfile,"syslog"))
		{
		//syslog
		filestr = NULL;
		do_syslog = 1;
		}
#endif
	else 
		{
		//filename
		filestr = strdup(logfile);
		}
#ifndef WIN32
	if(do_syslog)
		{
		openlog(OPENLOG_NAME,LOG_CONS,LOG_USER);
		}
	else
#endif
		{
		if(filestr == NULL)
			{
			fd = stdout;
			}
		else
			{
			log_rotate(filestr);
			log_file_name=(char*)strdup(filestr);
			fd = fopen(filestr,"a");
			if(strcmp("/dev/null",filestr))
				chmod(filestr,S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP);
			}
		if(fd == NULL)
			fprintf(stderr, "UNABLE TO OPEN LOGFILE: %s\n",
				filestr == NULL ? "stdout" : filestr);
		}
	
	free(filestr);
#endif

#if (defined(WIN32) && !defined(CYGWIN)) || defined(BEOS)
	if(logfile == NULL)
		logfile = strdup("log.txt");
	
	log_rotate(logfile);
	log_file_name=(char*)strdup(logfile);

	fd = fopen(logfile, "a");
	if (fd == NULL)
		fprintf(stderr, "UNABLE TO OPEN LOGFILE: %s\n",logfile);

#endif
		
	free(logfile);
	return 0;
}


int log_end()
{
	pthread_mutex_lock(&mutex);

	if (fd)
		fclose(fd);
	return 0;
}


int logit(char* zone, char* preamble, char*filename,int line,char *str, ...)
{
	// the string that will be printed
	char *logstr = NULL;
	// the string the user wants to print
	char *strtmp = NULL;
	
	int logstr_len,rc;
	va_list args;

	// lock the logging media
	pthread_mutex_lock(&mutex);

	// create and clean the buffer for the user string
	strtmp = (char *) malloc(MAX_LOG_STRING);
	memset(strtmp, '\0', MAX_LOG_STRING);

	// fill the buffer for the user string
	va_start(args, str);
	rc = vsnprintf(strtmp, MAX_LOG_STRING, str, args);
	va_end(args);

	if (preamble == NULL)
		logstr_len = strlen(zone) + strlen(ZONE_POSTPEND) + 
			strlen(strtmp) + 1;
	else 
		// +1 is for "\0" , + 3 is for "(,)"
		logstr_len = strlen(preamble) +
			strlen(filename) + MAX(B(line),4) + 
			strlen(ZONE_POSTPEND) + strlen(strtmp) + 4;
	
	// allocate logstr
	logstr = (char *) malloc(logstr_len);
	MALLOC_CHECK(logstr);

	// create logstr (all data wanted by the user)
	if (preamble == NULL)
		snprintf(logstr,logstr_len,"%s%s%s",zone,ZONE_POSTPEND,strtmp);
	else
		snprintf(logstr,logstr_len,"%s(%s,%4d)%s%s",
			preamble,filename,line,ZONE_POSTPEND,strtmp);

#ifndef WIN32
	if (do_syslog) {
		// syslog adds date and process name
		syslog(LOG_DEBUG, "%s", logstr);
	} else {
#endif
		
		// syslog adds date and process name, here we have to do it
		// by hand
		
		struct tm *newtime = NULL;
		time_t aclock;
		char timestr[30];	//see the manpage
		regmatch_t p;

		/* Get time in seconds */
		time(&aclock);
		/* Convert time to struct tm form  */
		newtime = localtime(&aclock);

		free(strtmp);
		strtmp = (char *) malloc(MAX_LOG_STRING + 1);
		memset(strtmp, '\0', MAX_LOG_STRING + 1);

		strncpy(timestr, asctime(newtime), 30);

		/* remove the \n at the end */
		p = regfind(timestr, "\n");
		if (p.begin != -1)
			timestr[p.begin] = '\0';

		rc = snprintf(strtmp, MAX_LOG_STRING, "%s %s: %s", timestr,
			 OPENLOG_NAME, logstr);
	
		// put an endline if the string was truncated
		if (rc >= MAX_LOG_STRING-1 && strtmp[MAX_LOG_STRING-2] != '\n')
			strtmp[MAX_LOG_STRING-2] = '\n';

		fprintf(fd, "%s", strtmp);
		fflush(fd);

#ifndef WIN32
	}
#endif
	
	free(strtmp);
	free(logstr);

	pthread_mutex_unlock(&mutex);

	return 0;
}

int log_get_verbosity()
{
return verbose_output;
}

void log_set_verbosity(int v)
{
verbose_output = v;
}

char *log_get_logfile(){
	return(log_file_name);
}



