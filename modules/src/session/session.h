#ifndef SESSION_H
#define SESSION_H
void  session_save(const char* key,const char* data,int overwrite);
//! NULL means not foud, "\a" meas locked
const char* session_load_and_lock(const char* key);
void  session_remove(const char* key);
void  session_unlock(const char* key);
#endif
