#ifndef SESSION_H
#define SESSION_H
void  session_save(char* key, char* data,int overwrite);
//! NULL means not foud, "\a" meas locked
char* session_load_and_lock(char* key);
void  session_remove(char* key);
void  session_unlock(char* key);
#endif
