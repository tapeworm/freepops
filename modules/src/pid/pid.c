/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 * 	Implements pid file
 * Notes:
 * 	retrieve_pid_file() by Stefano Falsetto <falsetto@gnu.org>
 * 	
 * Authors:
 * 	Simone Vellei <simone_vellei@users.sourceforge.net>
 ******************************************************************************/

#include <stdio.h>

#include "pid.h"

#include "log.h"
#define LOG_ZONE "PID"
#define NOBODY 65534

#if !(defined(WIN32) && !defined(CYGWIN))



static char *pidfile = NULL;

int create_pid_file(char *filestr)
{

	
	FILE *fp;

	//if (getuid() != IMROOT) 		
	//	return	PIDERROR;
	
	// mantains global pid file name
	pidfile = strdup(filestr);

	if (!pidfile)
		return PIDERROR;
	fp = fopen(pidfile, "w");
	if (fp) {
		SAY("Maintaining pid file \"%s\"\n",pidfile);
		fprintf(fp, "%ld\n", (long) getpid());
		fclose(fp);
		chmod(pidfile, S_IREAD | S_IWRITE);
	} else {
		SAY("Cannot create pid file \"%s\"\n",pidfile);
		return PIDERROR;
	}

	return PIDSUCCESS;

}

int remove_pid_file(void)
{

	FILE *tmpfd;
	
	//if (getuid() != IMROOT) 		
	//	return	PIDERROR;

	tmpfd=fopen(pidfile,"r");
	
	if (tmpfd!=NULL) {
		
		fclose(tmpfd);
		unlink(pidfile);
		return PIDSUCCESS;

	} else {
	
		
		SAY("Cannot delete pid file \"%s\"\n",pidfile);
		
		return PIDERROR;
	}
}

int retrieve_pid_file(char* pidfile)
{
	FILE 	*tmpfd;
	long	this_pid;

	tmpfd=fopen(pidfile,"r");
	
	if (tmpfd!=NULL) {
		SAY("Retriving info from pid file \"%s\"\n",pidfile);
		fscanf(tmpfd, "%ld", &this_pid);
		SAY("The retrived pid is: \"%d\"\n",this_pid);
		fclose(tmpfd);
		return this_pid;

	} else {
	
		SAY("Cannot retrive pid file \"%s\"\n",pidfile);
		
		return PIDERROR;
	}
}
#endif
