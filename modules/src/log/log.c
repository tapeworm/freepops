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

#include "regularexp.h"
#include "log.h"
#define LOG_ZONE "LOG"

#define HIDDEN static

#define OPENLOG_NAME "freepopsd"

/******************************************************************************/

HIDDEN int verbose_output = 0;
HIDDEN FILE *fd = NULL;
HIDDEN int syslogmode = 0;
HIDDEN char *log_file_name = NULL;

#ifndef WIN32
HIDDEN int do_syslog = 0;
#endif

#define ZONE_POSTPEND 	"-> "

/******************************************************************************/

HIDDEN pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

int file_exists(char *filename) {
	
	FILE *fp;
	fp = fopen(filename,"r");

	if(fp != NULL){
		fclose(fp);
		return(1);
	}
	else
		return(0);
}

char *get_free_logfile(char *logfile){

	int suffix=-1;
	char *str=(char*)malloc(strlen(logfile)+3);
	
	do {	
		suffix++;
		memset(str,0,(strlen(logfile)+3));
		sprintf(str,"%s.%d",logfile,suffix);
	} while(file_exists(str));
	
	return(str);
}

void copy_file(char *src, char* dst){

	FILE *fpin, *fpout;

	char buf[512];
	int n;

	fpin = fopen(src,"r");
	fpout = fopen(dst,"w");

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
	
	if (rc != -1 && filestats.st_size > MAX_LOG_SIZE){
		char *freefile=get_free_logfile(logfile);
		// creates backup file
		copy_file(logfile, freefile);
		free(freefile);
		if(fd != NULL)
			fclose(fd);
		remove(logfile);
	}

	if(reopen)
		fd = fopen(logfile, "a");
	
	pthread_mutex_unlock(&mutex);

	return 0;
}



int log_init(char* logfile, int sysmode)
{
#if (!defined(WIN32)) && (!defined(BEOS))
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
	else if (!strcmp(logfile,"syslog"))
		{
		//syslog
		filestr = NULL;
		do_syslog = 1;
		}
	else 
		{
		//filename
		filestr = strdup(logfile);
		}

	if(do_syslog)
		{
		openlog(OPENLOG_NAME,LOG_CONS,LOG_USER);
		}
	else
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

#if defined(WIN32) || defined(BEOS)
	if(logfile == NULL)
		logfile == strdup("log.txt");
	
	log_rotate(logfile);
	log_file_name=(char*)strdup(logfile);

	fd = fopen(logfile, "a");
	if (fd == NULL)
		fprintf(stderr, "UNABLE TO OPEN LOGFILE: %s\n",logfile);

#endif
	syslogmode = sysmode;
		
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


int logit(char* zone, char *str, ...)
{
	char *logstr = NULL;
	char *strtmp = NULL;
	int logstr_len,rc;
	va_list args;

	//fprintf(fd,"start\n");
	pthread_mutex_lock(&mutex);

	strtmp = (char *) malloc(MAX_LOG_STRING);
	memset(strtmp, '\0', MAX_LOG_STRING);

	va_start(args, str);
	rc = vsnprintf(strtmp, MAX_LOG_STRING, str, args);
	va_end(args);

	if (rc >= MAX_LOG_STRING - 1 && strtmp[MAX_LOG_STRING-2] != '\n')
		strtmp[MAX_LOG_STRING-2] = '\n';

	if(syslogmode){
		/* +1 is for \0 */
		logstr_len = strlen(zone) + strlen(ZONE_POSTPEND) + 
			strlen(strtmp) + 1;
		logstr = (char *) malloc(logstr_len);
		MALLOC_CHECK(logstr);

		snprintf(logstr, logstr_len, "%s%s%s", 
			zone,ZONE_POSTPEND,strtmp);
	}else{
		logstr = strdup(strtmp);
	}

#ifndef WIN32
	// I want to log in syslog file 
	if (do_syslog) {
		syslog(LOG_DEBUG, logstr);
	} else {
#endif
		if(syslogmode){
			// insert name, date and time values
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

			snprintf(strtmp, MAX_LOG_STRING, "%s %s: %s", timestr,
				 OPENLOG_NAME, logstr);
		}else{
			free(strtmp);
			strtmp = strdup(logstr);
		}

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



