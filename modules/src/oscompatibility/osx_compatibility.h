#ifdef MACOSX

/*******************************************************************
 * This is a bad hack, since a mutex is owned by the locker,
 * while a semaphore not. So we use a passing le baton technique
 * with mutex. This seems to work on macosx that lacks 
 * semaphore implementation. But is not semantically correct.
 *******************************************************************/ 

#define sem_t pthread_mutex_t
#define sem_wait(s) pthread_mutex_lock(s)
#define sem_post(s) pthread_mutex_unlock(s)
#define sem_init(s,a,b) (__extension__(\
	{\
	pthread_mutex_t __tmp = PTHREAD_MUTEX_INITIALIZER;\
	*(s) = __tmp;\
	if((b) == 0)\
		pthread_mutex_lock(s);\
	if((b) > 1 || (b) < 0 )\
		abort();\
	0;\
	}\
))
#define sem_destroy(s) pthread_mutex_destroy(s)

#define snprintf(a,b,c...) (__extension__			\
			({ 					\
			int __result;				\
			if ( a == NULL && b == 0)		\
				__result = c99_snprintf(c);	\
			else					\
				__result = snprintf(a,b,c);	\
			__result; }))

#define vsnprintf(a,b,c,d) (__extension__			\
			({ 					\
			int __result;				\
			if ( a == NULL && b == 0)		\
				__result = c99_vsnprintf(c,d);\
			else					\
				__result = vsnprintf(a,b,c,d);	\
			__result; }))

#endif
