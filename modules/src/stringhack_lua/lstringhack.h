#ifndef LSTRINGHACK_H
#define LSTRINGHACK_H

struct strhack_t* new_str_hack();
void delete_str_hack(struct strhack_t* x);
char * dothack(char *buff,struct strhack_t*a);
char *tophack(char* tmp,int lines,struct strhack_t *a);
int check_stop(int lines,struct strhack_t *a);

#endif
