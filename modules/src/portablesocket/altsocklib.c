/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/

/******************************************************************************
 * File description:
 *	Win32-POSIX socket compatibility layer
 * Notes:
 *	The user should use the upper layer socketcommon.h
 * Authors:
 * 	Gerald Dueck
 * 	Andrew Lynch
 * 	Enrico Tassi <gareuselesinge@users.sourceforge.net>
 * Change History:
 *   07sep97: created
 *   24Sep97: added sockinfo, senddata, recvdata
 *   Jan-Feb00: modified for NT/UNIX transparency
 *   Sep02: Andrew Lynch added timeout option to recvstring  
 *   Oct03: Enrico Tassi removed sock_listen (implemented in the upper layer
 *   	socketcommon.[ch])
 *   Jan04: Enrico Tassi More fix (EINTR prone), restylings, ....
 *
 ******************************************************************************/

#if defined(WIN32) && !defined(CYGWIN)
 #include <winsock.h>
 #include <process.h>
 #include <io.h>
 #include <stdio.h>
 #include <unistd.h>
 #include <sys/time.h>
 #include <sys/types.h>
 #include <errno.h>
 #include <pthread.h>
#else /* #ifndef WIN32 */
 #include <netdb.h>
 #ifndef FREEBSD
   #include <netinet/in.h>
 #endif
 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <sys/types.h>
 #include <sys/socket.h>
 #include <sys/time.h>
 #include <sys/uio.h>
 #include <unistd.h>
 #include <errno.h>

 /* on some libc there is no _r support */
 #ifndef strerror_r

  # include <pthread.h>
  pthread_mutex_t strerror_lock = PTHREAD_MUTEX_INITIALIZER;
  # define strerror_r(a,b,c) {\
	pthread_mutex_lock(&strerror_lock);\
	snprintf(b,c,"%s",strerror(a));\
	pthread_mutex_unlock(&strerror_lock);\
  }

 #endif /* ndef strerror_r */
 
 /* macro to check result of send() */
 #define CHECK_RC(rc) (__extension__(\
		{\
		long int __result=0;\
		if(rc == -1)\
			{\
			char buff[100];\
			strerror_r(errno,buff,100);\
			SAY("%s : %s : %d : (%d)%s\n",\
				__FILE__,__FUNCTION__,__LINE__,errno,buff);\
			__result = 1;\
			}\
		__result;\
		}))

#endif /* ndef WIN32 */


/* unistd GNU macro to avoid EINTR */
#define TEMP_FAILURE_RETRY(expression) \
  (__extension__                                  \
    ({ long int __result;                              \
       do __result = (long int) (expression);                      \
       while (__result == -1L && errno == EINTR);                  \
       __result; }))


#ifndef MSG_NOSIGNAL
  # define MSG_NOSIGNAL 0
#endif

#include "altsocklib.h"
#include "beos_compatibility.h"

#include "log.h"
#define LOG_ZONE "ALTSOCKLIB"

#if defined(WIN32) && !defined(CYGWIN)
static struct {
	int errorNumber;
	char *errorString;
} sockerrlist [] = {
	{10013, "Permission denied"},
	{10048, "Address already in use"},
	{10049, "Cannot assign requested address"},
	{10047, "Address family not supported by protocol family"},
	{10037, "Operation already in progress"},
	{10053, "Software caused connection abort"},
	{10061, "Connection refused"},
	{10054, "Connection reset by peer"},
	{10039, "Destination address required"},
	{10014, "Bad address"},
	{10064, "Host is down"},
	{10065, "No route to host"},
	{10036, "Operation now in progress"},
	{10004, "Interrupted function call"},
	{10022, "Invalid argument"},
	{10056, "Socket is already connected"},
	{10024, "Too many open files"},
	{10040, "Message too long"},
	{10050, "Network is down"},
	{10052, "Network dropped connection on reset"},
	{10051, "Network is unreachable"},
	{10055, "No buffer space available"},
	{10042, "Bad protocol option"},
	{10057, "Socket is not connected"},
	{10038, "Socket operation on non-socket"},
	{10045, "Operation not supported"},
	{10046, "Protocol family not supported"},
	{10067, "Too many processes"},
	{10043, "Protocol not supported"},
	{10041, "Protocol wrong type for socket"},
	{10058, "Cannot send after socket shutdown"},
	{10044, "Socket type not supported"},
	{10060, "Connection timed out"},
	{10109, "Class type not found"},
	{10035, "Resource temporarily unavailable"},
	{11001, "Host not found"},
	{10093, "Successful WSAStartup not yet performed"},
	{11004, "Valid name; no data record of requested type"},
	{11003, "Non-recoverable error"},
	{10091, "Network subsystem is unavailable"},
	{11002, "Non-authoritative host not found"},
	{10092, "WINSOCK.DLL version out of range"},
	{10094, "Graceful shutdown in progress"},
	{0, NULL}
	}; 
#endif

void sockerror(char *msg) {
#if defined(WIN32) && !defined(CYGWIN)
	int err = WSAGetLastError();
	int i;
	for (i = 0; sockerrlist[i].errorNumber; i++)
		if (sockerrlist[i].errorNumber == err) {
			fprintf(stderr, "%s: (%d) %s\n", msg, err,
				sockerrlist[i].errorString);
			SAY("%s: (%d) %s\n", msg, err, 
				sockerrlist[i].errorString);
			return;
		}
#else
	
	SAY("'%s' : ",msg);
	CHECK_RC(-1);
#endif
}

/* === HERE WE HAVE THE REAL CODE =========================================== */

/*********************************************************
 *
 * gethostbyname thread safe implementation ipv4 only
 * probably endian dependent (win runs on big endians?)
 *
 */ 
#if !(defined(WIN32) || defined(CYGWIN))
static unsigned int gethostbyname_thsafe (char *host)
{
  int res;
  unsigned int dst;
  struct addrinfo hint, *addr;

  memset(&hint, 0, sizeof(hint));
  hint.ai_family = PF_INET;
  res = getaddrinfo(host, NULL, &hint, &addr);
 
  /*  Check for errors.  */
  if (res)
	return 0xffffffff;
  
  dst = ((struct sockaddr_in *)(addr->ai_addr))->sin_addr.s_addr;
  freeaddrinfo(addr);

  return dst;
}
#else

static pthread_mutex_t mutex_for_gethostbyname = PTHREAD_MUTEX_INITIALIZER;

static unsigned int gethostbyname_thsafe (char *host)
{
struct hostent  *hp;
unsigned int h;

pthread_mutex_lock(&mutex_for_gethostbyname);
hp = gethostbyname(host);
if(hp != NULL)
	h = ((struct in_addr *) (hp->h_addr))->s_addr;
else
	h = 0xffffffff;
pthread_mutex_unlock(&mutex_for_gethostbyname);

return h;
}
#endif

/********************************************
 *
 * win32 needs to be initialized even before 
 * calling gethostbyname(), so we call this
 *
 */ 
#if defined(WIN32) && !defined(CYGWIN)
void sockinit()
{
static int started = 0;
if (!started) 
	{
	short wVersionRequested = 0x101;
	WSADATA wsaData;
	if (WSAStartup( wVersionRequested, &wsaData ) == -1) 
		{
		sockerror("sockopen");
		exit(0);
		}
	if (wsaData.wVersion != 0x101) 
		{
		fprintf(stderr, "Incorrect winsock version\n");
		exit(0);
		}
	started = 1;
	}
}
#endif

/*********************************************************
 * This is a dual purpose routine.
 * - if host is not NULL, connect as a client to the given 
 *   host and port.
 * - if host is NULL, bind a socket to the given port.
 * In either case, return a valid socket or -1.
 */
int sockopen(char *host, struct in_addr bind_add, unsigned short port)
{
int sd;
struct sockaddr_in sin;
unsigned int add;
    
#if defined( WIN32) && !defined(CYGWIN)
sockinit();
#endif

/* get an internet domain socket */
if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	return -1;

/* complete the socket structure */
memset(&sin, 0, sizeof(sin));
sin.sin_family = AF_INET;
sin.sin_port = htons(port);
    
if (host != NULL) 
    	{
        /* get the IP address of the requested host */
    
	if ((add = gethostbyname_thsafe(host)) == 0xffffffff)
        	return -1;

        sin.sin_addr.s_addr = add;

	//FIX memory leak for hp
	
	if (connect(sd, (struct sockaddr *) &sin, sizeof(sin)) == -1)
		return -1;
	} 
else 
	{                    
	/* server */
	int one = 1;
	
        /* avoid "bind: socket already in use" msg */
        if (setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, (char *) &one, 
				sizeof(one)) < 0)
		return -1;
	
	/* let you bind different from 0.0.0.0 */
	sin.sin_addr.s_addr = bind_add.s_addr;
	
        /* bind the socket to the port number */
        if (bind(sd, (struct sockaddr *) &sin, sizeof(sin)) == -1)
	return -1;
    	}

return sd;
}

/********************************************
 *
 * get some info aboute the socket
 *
 *
 */ 
int sockinfo(int sd, char *info)
{
    struct sockaddr_in sin;
#ifndef WIN32
    socklen_t len = sizeof(sin);
#else
    int len = sizeof(sin);
#endif
    memset(&sin, 0, sizeof(sin));
    if (getsockname(sd, (struct sockaddr *) &sin, &len) == -1) {
		sockerror("sockinfo");
		return -1;
	}
    memcpy(info, &sin.sin_addr, 4);
    memcpy(info + 4, &sin.sin_port, 2);
    return 0;
}

/***************************************************
 *
 * pretty close the socket truncating connections
 *
 */ 
int sockclose(int sock)
{
#if defined(WIN32) && !defined(CYGWIN)
	shutdown(sock, SD_BOTH);
	return closesocket(sock);
#else
	shutdown(sock,SHUT_RDWR);
	return close(sock);
#endif
}

/******************************************************************
 * senddata 
 *    - appends <CR><LF> before transmitting data through socket.
 *    - is O(n) where n is sizeo of stream
 *    - is not SIG_PIPE prone
 * bugs:
 *    - WIN32 implementation should be rewritten using WSASend
 */

int senddata(int socket, char *buffer, int length)
{
#if !(defined(WIN32) && !defined(CYGWIN))
    static char crlf[] = "\r\n";
    int rc;
    
    for(rc=0;rc < length;)
	{
	rc = TEMP_FAILURE_RETRY(
		send(socket,&buffer[rc],length-rc,MSG_NOSIGNAL));
	if(CHECK_RC(rc))
		return -1;
	}
    
    for(rc=0;rc < 2;)
	{
	rc = TEMP_FAILURE_RETRY(send(socket,&crlf[rc],2-rc,MSG_NOSIGNAL));
	if(CHECK_RC(rc))
		return -3;
	}

    return length;
#endif
#if defined(WIN32) && !defined(CYGWIN)
	char *buffer2 = (char *)malloc(length+2);
	int rc;
	
	memcpy(buffer2, buffer, length);
	memcpy(buffer2+length, "\r\n", 2);
	
	for(rc=0;rc < length;)
		{
		rc = TEMP_FAILURE_RETRY(send(socket, buffer2, length+2-rc, 0));
		if ( rc < 0)
			length -= 2;
		}
	free(buffer2);
	return length;
#endif
}

/***********************************************************************
 * senddata_raw
 *    - NOT appends <CR><LF> before transmitting data through socket.
 *    - is O(n) where n is sizeo of stream
 *    - is not SIG_PIPE prone
 * bugs:
 *    - WIN32 implementation should be rewritten using WSASend
 */
int senddata_raw(int socket,const char *buffer, int length)
{
#if !(defined(WIN32) && !defined(CYGWIN))
    int rc;
    
    for(rc=0;rc < length;)
	{
	rc = TEMP_FAILURE_RETRY(
		send(socket,&buffer[rc],length-rc,MSG_NOSIGNAL));
	if(CHECK_RC(rc))
		return -1;
	}
    
    return length;
#endif
#if defined(WIN32) && !defined(CYGWIN)
	int rc;
	
	for(rc=0;rc < length;)
		{
		rc = TEMP_FAILURE_RETRY(send(socket, buffer, length-rc, 0));
		}
	return length;
#endif
}

/***************************************************************************
 * recvdata
 *    - extracts <cr><lf>-delimited record from socket stream
 *    - works with fragmented socket stream
 *    - fragments returned records correctly if sent size > maxsize
 *    - works correctly with any size recvbuffer
 *    - is O(n) where n = sizeof stream
 * bugs:
 *    - uses static state information and hence must always be
 *      called with the same socket. If called with two different sockets,
 *      call with second socket may return data left over from call with
 *      first socket.
 */
int recvdata(int socket, char *buffer, int maxsize)
{
    static char recvbuffer[1024];
    static char *bufp = recvbuffer,
     *bufe = recvbuffer;
    char *dst = buffer;
    static enum {
        stData, stCr, stCopy
    } state = stData;
    while (dst - buffer < maxsize) {
        if (bufp == bufe) {
            int length = recv(socket, recvbuffer, sizeof(recvbuffer), 0);
            if (length < 0)
	    	{
		if (dst - buffer > 0)
                    return dst - buffer;
                else
                    return length;
		}
            bufp = recvbuffer;
            bufe = recvbuffer + length;
            if (length == 0) {
				*dst= 0;
                break;
			}
        }
        switch (state) {
            case stData:
                if (*bufp == '\r') {
                    state = stCr;
                    bufp++;
                } else
                    *dst++ = *bufp++;
                break;
            case stCr:
                if (*bufp == '\n') {
                    state = stData;
                    bufp++;
                    return dst - buffer;
                } else {
                    state = stCopy;
                    *dst++ = '\r';
                }
                break;
            case stCopy:
                *dst = *bufp++;
                state = stData;
                break;
        }
    }
	buffer[maxsize-1] = '\0';
    return maxsize;
}

/*************************************************************************
 * recvstring
 *    - like recvdata but without the bugs.
 *    - requires an initialized recvbuffer_t.
 *    - extracts <cr><lf>-delimited record from socket stream
 *    - works with fragmented socket stream
 *    - fragments returned records correctly if sent size > maxsize
 *    - works correctly with any size recvbuffer
 *    - is O(n) where n = sizeof stream
 */

recvbuffer_t *recvBufferCreate(int size) {
	recvbuffer_t *rb = (recvbuffer_t *) malloc (sizeof(recvbuffer_t));
	rb->recvbuffer = (char *)malloc(size);
	rb->bufp = rb->recvbuffer;
	rb->bufe = rb->recvbuffer;
	rb->size = size;
	return rb;
}

void recvBufferDestroy(recvbuffer_t *rb) {
	free(rb->recvbuffer);
	free(rb);
}

int recvstring(int socket, char *buffer, int maxsize, recvbuffer_t *rb)
{
    char *dst = buffer;
    static enum {
        stData, stCr, stCopy
    } state = stData;

    while (dst - buffer < maxsize -	1)
    	{
        if (rb->bufp == rb->bufe)
		{
        	int length;
		
		length = recv(socket, rb->recvbuffer, rb->size, MSG_NOSIGNAL);
            	
            	if (length < 0)
	    		{
			if (dst - buffer > 0)
				{
				*dst = '\0';
	                	return dst - buffer;
	                	}
			else 	
				{
				buffer[0] = '\0';
	                    	return length;
				}
			}
	        rb->bufp = rb->recvbuffer;
        	rb->bufe = rb->recvbuffer + length;

	        if (length == 0)
        	    	{
			*dst = '\0';
		        break;
			}
        	}
        switch (state)
        	{
	        case stData:
                	if (*rb->bufp == '\r')
                		{
		                state = stCr;
        		        rb->bufp++;
                		}
               		else
                		*dst++ = *rb->bufp++;

                	break;
            	case stCr:
                	if (*rb->bufp == '\n')
                		{
		        	state = stData;
        		        rb->bufp++;
				*dst = '\0';
                    		return dst - buffer;
		               	}
			else
				{
			        state = stCopy;
        			*dst++ = '\r';
	                	}
        	       break;
	        case stCopy:
                	*dst = *rb->bufp++;
                	state = stData;
	                break;
        	}
    }

buffer[maxsize-1] = '\0';
return maxsize;
}

int recvstring_with_timeout(int socket, char *buffer, int maxsize, recvbuffer_t *rb, int timeout)
{
    char *dst = buffer;
    static enum {
        stData, stCr, stCopy
    } state = stData;

    while (dst - buffer < maxsize -	1)
    	{
		
        if (rb->bufp == rb->bufe)
		{
            int length;
        	
		fd_set fds;
		int n;
		struct timeval tv;
		
		// set up the file descriptor set
		FD_ZERO(&fds);
		FD_SET(socket, &fds);

		// set up the struct timeval for the timeout
		tv.tv_sec = timeout;
		tv.tv_usec = 0;

		// wait until timeout or data received
		n = select(socket+1, &fds, NULL, NULL, &tv);
		if (n == 0) return -2; // timeout!
		if (n == -1) return -1; // error

		// data must be here, so do a normal recv()

		length = recv(socket, rb->recvbuffer, rb->size, MSG_NOSIGNAL);
            	
            	if (length < 0)
	    		{
			if (dst - buffer > 0)
				{
				*dst = '\0';
	                	return dst - buffer;
	                	}
			else 	
				{
				buffer[0] = '\0';
	                    	return length;
				}
			}
	        rb->bufp = rb->recvbuffer;
        	rb->bufe = rb->recvbuffer + length;

	        if (length == 0)
        	    	{
			*dst = '\0';
		        break;
			}
        	}
        switch (state)
        	{
	        case stData:
                	if (*rb->bufp == '\r')
                		{
		                state = stCr;
        		        rb->bufp++;
                		}
               		else
                		*dst++ = *rb->bufp++;

                	break;
            	case stCr:
                	if (*rb->bufp == '\n')
                		{
		        	state = stData;
        		        rb->bufp++;
				*dst = '\0';
                    		return dst - buffer;
		               	}
			else
				{
			        state = stCopy;
        			*dst++ = '\r';
	                	}
        	       break;
	        case stCopy:
                	*dst = *rb->bufp++;
                	state = stData;
	                break;
        	}
    }

buffer[maxsize-1] = '\0';

return maxsize;
}

int sendstring(int socket, char *string) {
	return senddata(socket, string, strlen(string));
}

int sendstring_raw(int socket, const char *string) {
	return senddata_raw(socket, string, strlen(string));
}
