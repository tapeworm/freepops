#include "logl.h"
#include "log.h"
#define LOG_ZONE "LUA_LOG"

void dbg(char* s) {DBG(s);}
void say(char* s) {SAY(s);}
void error_print(char* s) {ERROR_PRINT(s);}
void error_abort(char* s) {ERROR_ABORT(s);}

