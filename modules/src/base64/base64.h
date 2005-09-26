/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   base64.h
  * \brief  base64 encoding
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/

#ifndef _BASE64_H_
#define _BASE64_H_

//! base64 encoding
char *base64enc_raw(const char *input,size_t len);
//! base64 encoding
char *base64enc(const char *input);
//! base64 decoding
char *base64dec(const char *input, size_t len);


#endif
