/******************************************************************************
 * $Id$
 * This file is part of FreePOPs (http://freepops.sf.net)                     *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   lstringhack.h
  * \brief  string hacking for lua
  * 
  * \author Name <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/
#ifndef LSTRINGHACK_H
#define LSTRINGHACK_H

struct strhack_t* new_str_hack();
void delete_str_hack(struct strhack_t* x);
char * dothack(struct strhack_t*a,const char *buff);
char *tophack(struct strhack_t *a,const char* tmp,int lines);
int check_stop(struct strhack_t *a,int lines);
int current_lines(struct strhack_t *a);

#endif
