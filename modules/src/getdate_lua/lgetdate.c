#include <stdlib.h>

#include "getdate.h"

long int lua_getdate(char* s)
{
return gd_getdate(s,NULL);
}
