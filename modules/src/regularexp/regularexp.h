/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   regularexp.h
  * \brief  Implements a layer for regex
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  * \author Alessio Caprari <alessiofender@users.sourceforge.net>
  */
/******************************************************************************/

#ifndef REGULAREXP_H_
#define REGULAREXP_H_

#include <sys/types.h>
#include <regex.h>

/** @name I hate rm_so/eo name! */
//@{
#define begin rm_so
#define end   rm_eo
//@}

/**
 *  Searches for a regular expression in the given string.
 *  @param from the source string
 *  @param exp the regular expression
 *  @return a struct with a begin and end fields
 */
regmatch_t regfind(const char* from,const char* exp);

/**
 * Searches for a regular expression in the given string,
 * returning only the starting offset.
 * @return The start offset of the match
 * @see regfind()
 */
regoff_t regfind_start(const char* from, const char* exp);

/**
 * Searches for a regular expression in the given string,
 * returning only the ending offset.
 * @return The end offset of the match
 * @see regfind()
 */
regoff_t regfind_end(const char* from, const char* exp);

/**
 * Searches for a regular expression in the given string,
 * returning the number of occurrences
 * @return the number of occurrences of exp in from
 * @see regfind()
 */
int regfind_count(const char* from, const char* exp);

#endif
