#include "lua.h"
#include "lauxlib.h"

#ifndef WIN32
    #include <string.h>
    #include <stdlib.h>
    #include <sys/types.h>
    #include <unistd.h>
    #include <sys/wait.h>
    #include <errno.h>
#define LUA_FILEHANDLE		"FILE*"
static FILE **newfile (lua_State *L) {
  FILE **pf = (FILE **)lua_newuserdata(L, sizeof(FILE *));
  *pf = NULL;  /* file handle is currently `closed' */
  luaL_getmetatable(L, LUA_FILEHANDLE);
  lua_setmetatable(L, -2);
  return pf;
}
#endif


static int io_dpopen(lua_State*l){
#if defined(WIN32)
  luaL_error(l, "`dpopen' not supported");
  return 0;
#else
	#define READ	0
	#define WRITE	1
	int in[2],out[2];
	int narg = lua_gettop(l);
	const char ** argv = NULL;
	int i,rc;
	pid_t pid;
	FILE **pf_r,**pf_w;


	if (narg < 1) {
		luaL_error(l,"create wants at least one argument");
	}
	
	argv = calloc(narg+1,sizeof(char*));
	if (argv == NULL){
		luaL_error(l,"Unable to alloc.");
	}

	for (i=0;i < narg;i++) {
		argv[i] = luaL_checkstring(l,i+1);
		//fprintf(stderr,"getting %s",argv[i]);
	}
	argv[i] = NULL;
	
	rc = pipe(out);
	if (rc == -1) {
		luaL_error(l,strerror(errno));
	}
	rc = pipe(in);
	if (rc == -1) {
		luaL_error(l,strerror(errno));
	}

	pid = fork();
	if (pid == 0) {
		// son
		pid = fork();
		if (pid == 0) {
			// grandson, inherited by init, no Zombie
			rc = dup2(out[READ],STDIN_FILENO);
			if (rc == -1) {
				luaL_error(l,strerror(errno));
			}
			rc = dup2(in[WRITE],STDOUT_FILENO);
			if (rc == -1) {
				luaL_error(l,strerror(errno));
			}
			rc = close(in[READ]);
			if (rc == -1) {
				luaL_error(l,strerror(errno));
			}
			rc = close(out[WRITE]);
			if (rc == -1) {
				luaL_error(l,strerror(errno));
			}
			//fprintf(stderr,"starting %s...\n",argv[0]);
			rc = execv(argv[0],(char* const*)argv);
			if (rc == -1) {
				luaL_error(l,strerror(errno));
			}
			luaL_error(l,"dead code");
		} else {
			_exit(0);
		}
	} else {
		if (pid == -1) {
			luaL_error(l,strerror(errno));
		}
		waitpid(pid,NULL,0); //wait the son
	}
	pf_r = newfile(l);
	pf_w = newfile(l);

	rc = close(out[READ]);
	if (rc == -1) {
		luaL_error(l,strerror(errno));
	}
	rc = close(in[WRITE]);
	if (rc == -1) {
		luaL_error(l,strerror(errno));
	}
	
	*pf_r = fdopen(in[READ],"r");
	*pf_w = fdopen(out[WRITE],"w");

	//sleep(2);

	free(argv);
	
	return 2;
#endif
}

int luaopen_dpipe(lua_State* L){
	lua_getglobal(L,"io");
#ifndef WIN32
        lua_pushstring(L,"dpopen");      /* io, 'dpopen' */
	lua_pushcfunction(L, io_dpopen); /* io, 'dpopen', dpopen */
	lua_getfield(L,-3,"open");       /* io, 'dpopen', dpopen, open */
	lua_getfenv(L,-1);               /* io, 'dpopen', dpopen, open, env*/
	lua_setfenv(L, -3);              /* io, 'dpopen', dpopen, open */
	lua_pop(L,1);                    /* io, 'dpopen', dpopen */
	lua_settable(L,-3);              /* io */
#endif
	return 1;
}
