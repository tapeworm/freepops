/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   mlex.h
  * \brief  Markup Language EXpression
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  */
/******************************************************************************/


#ifndef MLEX_H
#define MLEX_H

#include "list.h"

//! the struct that is used to identify a piece of string
struct chunk_t
	{
	int start,stop;
	};

//! \brief Finds Markup Language chuks matching exp
/*!
 * <B>What is an ml-expression?</B><BR>
 * Simply a regular expression with some 
 * more infos about murkups.<BR>
 * <I>Grammar:</I>
 *  <UL>
 *  <LI><b>MLEX</b> := <b>MREGEX</b> | <b>MTAGEX</b> | <b>MLEX</b> <b>MLEX</b> | '' </LI>
 *  <LI><b>MTAGEX</b> := '{'<b>REGEX</b>'}' | '<'<b>REGEX</b>'>'</LI>
 *  <LI><b>MREGEX</b> := '['<b>REGEX</b>']' | <b>REGEX</b></LI>
 *  <LI><b>REGEX</b> := regular expression</LI>
 *  </UL>
 * <I>Example:</I>
 *  <UL>
 *  <LI><TT>".*<b>([0-9]*(Kb|Mb))</b>"</TT><BR>
 *  This matches a generic size in bold.</LI>
 *  <LI><TT>".*<(b|i)>([0-9]*(Kb|Mb))</(b|i)>"</TT><BR>
 *  This matches a generic size in bold or italics, obviously it doesn't check
 *  if it opens with a <B>b</B> and closes with a <B>/i</B>.</LI>
 *  <LI><TT>"a<b>[c]{d}e{f}[g]<h>"</TT><BR>
 *  This matches abdefgh, abeh and othe strigs created considering optionals
 *  the tags/strings between <TT>{}</TT> and <TT>[]</TT>
 *  </LI>
 *  </UL>
 * <I>Limitation:</I>
 *  <UL>
 *  <LI>You can use regular expressions inside tags or outside tags,but
 *  you can't use regexp with tags. For example it is impossible to specify
 *  an arbutrary number of <TT>"<b>"</TT>.</LI>
 *  <LI>A string, say an <b>MREGEX</b> not optional, cant start with 
 *  <TT>[</TT> since it is reserver for optional strings. You must put the
 *  expression into round brackets to avoid this.</LI>
 *  <LI>The parser is not really smart. It always alternates a string with
 *  a tag, so an xpression <TT>"<a><b>"</TT> is interpreted as this sequence
 *  of tokens: <TT>"","<a>","","<b>"</TT>.</LI>
 *  </UL>
 * <BR>
 * <B>What is an ml-get-expression?</B><BR> 
 * It is the counterpart of a ml-expression.
 * It selects what is important and what not.<BR>
 * <I>Grammar:</I>
 * <UL>
 * <LI><B>MLGEX</B> := <B>REGGEX</B> <B>TAGGEX</B>  | <B>MLGEX</B> <B>MLGEX</B> | ''</LI>
 * <LI><B>TAGGEX</B> := '<'<b>EX</b>'>' | '{'<b>EX</b>'}'</LI>
 * <LI><B>REGGEX</B> := <b>EX</b> | '['<b>EX</b>']'</LI>
 * <LI><B>EX</B> := 'X' | 'O'</LI>
 * </UL>
 * <I>Example:</I>
 * <UL>
 * <LI>If the ml-expression is 
 * <TT>".*<b>.*<.*img.*src.*>.*</b>"</TT> <BR>
 * and the ml-get-expression is 
 * <TT>"O<O>O<X>X<O>"</TT><BR>
 * and data is 
 * <TT>"<tt><b><img src="nice.jpg">hello</b>"</TT><BR> 
 * mlmatch returns a list of length 2
 * (read: the nember of <TT>"X"</TT>) the first defining  
 * <TT>"img src="nice.jpg""</TT> and the second defining 
 * <TT>"hello"</TT>.</LI>
 * </UL>
 * Remembre that if an optional string/tag is used in the ml-expression,
 * the corrspong optional string/tag signature must be used in 
 * the ml-get-expression.<BR>
 * <BR>
 * <I>A short explanation of how the engine works
 * (considering the prevoius example):</I><BR>
 * <OL>
 * <LI>
 * tokenize the strings:
 *  <UL>
 *  <LI><TT>"<tt><b><img src="nice.jpg">hello</b>"</TT> becames
 *   <TT>"","<tt>","","<b>","","<img src="nice.jpg">","hello","</b>"</TT></LI>
 *  <LI><TT>".*<b>.*<.*img.*src.*>.*</b>"</TT> becames 
 *   <TT>".*","<b>",".*","<.*img.*src.*>",".*","</b>"</TT></LI>
 *  <LI><TT>"O<O>O<X>X<O>"</TT> becames 
 *   <TT>"O","<O>","O","<X>","X","<O>"</TT></LI>
 *  </UL>
 * </LI>
 * <LI>
 *  The ml-expression matches perfectly the data starting from the third token,
 *  since each regexp matches the corresponding token. so we obtain this
 *  sub-list of tokens 
 *  <TT>"","<b>","","<img src="nice.jpg">","hello","</b>"</TT>
 * </LI>
 * <LI>
 *   The sublist has the same length of the ret expression and selecting only
 *   the tokens with a corresponding <tt>X</tt> we obtain
 *   {<TT>"img src="nice.jpg""</TT>,<TT>"hello"</TT>.</LI>}
 * </LI>
 * </OL>
 * <I>Notes:</I>
 * <UL>
 * <LI>data, exp and ret <B>MUST</B> be modifyable. 
 * they will not be altered, but
 * during processing they may be accessed in write.</LI>
 * </UL>
 *  
 * \param data is a Markup Language file like an html page (must be modifyable)
 * \param exp is the ml-expression (must be modifyable)
 * \param ret is the ml-get-expression (must be modifyable)
 * \return a list of list of chunk_t
 */ 
list_t* mlmatch(char* data, char* exp, char*ret);

//! debug functions that prints the resul matrix
void mlmatch_print_results(list_t*res,char* str);

//! free the list of lists returned by mlmatch
void mlmatch_free_results(list_t*res);


//! \brief gets a cell from the result matrix
/*! mlmatch returns a list of lists. this is a matrix.
 * each line is the list of <TT>X</TT> fields.
 * <I>Example:</I>
 * <UL>
 * <LI>
 * <TT>src</TT> := <TT>"<b>hello</b> bad <i>guys</b>"</TT><BR>
 * <TT>exp</TT> := <TT>"<.*>.*</b>"</TT><BR>
 * <TT>ret</TT> := <TT>"<X>X<O>"</TT><BR>
 * calling <BR>
 * <TT>rc = mlmatch(src,exp,ret);</TT><BR>
 * will return <BR>
 * <TT>{{"b","hello"},</TT><BR>
 * <TT>&nbsp;{"i","guys"}&nbsp;}</TT><BR>
 * and the respective coordinates are from <TT>0,0</TT> to <TT>1,1</TT>.
 * For example <TT>"hello"</TT> is <TT>1,0</TT>.
 * </LI>
 * The returned poiter must be freed by the caller.
 * </UL>
 *
 * \param x column
 * \param y row
 * \param res returned by mlmatch
 * \param s the src string
 * \return a strdup of s chunked in the right position
 *
 */ 
char* mlmatch_get_result(int x,int y,
		list_t* res,char* s);

#endif
