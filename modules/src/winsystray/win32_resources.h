/******************************************************************************
 * $Id$
 * This file is part of liberopops (http://liberopops.sf.net)                 *
 * This file is distributed under the terms of GNU GPL license.               *
 ******************************************************************************/


/******************************************************************************/
 /*!
  * \file   win32resources.h
  * \brief  windows PE resources
  * \author Enrico Tassi <gareuselesinge@users.sourceforge.net>
  * \author Nicola Cocchiaro <ncocchiaro@users.sourceforge.net>
  */
/******************************************************************************/

#define RES_ICON_16 	30
#define RES_MENU 	20
#define RES_MENU_HIDDEN 21
#define RES_MENU_EXIT 	22
#define RES_MENU_DOWNLOAD 24
#define RES_MENU_ABOUT  23
#define RES_MENU_NEWS	25
#define RES_ICON_32 	10

#define ABOUT_TITLE	"FreePOPs/" VERSION
#define ABOUT_STRING	"\
A software developed by:\n\
	Enrico Tassi\n\
\n\
This software is the evolution of LiberoPOPs, developed by:\n\	
	Alessio Caprari\n\
	Nicola Cocchiaro\n\
	Enrico Tassi\n\
	Giacomo Tenaglia\n\
	Simone Vellei\n\
\n\
For more infos look at the web site:\n\
	http://freepops.sourceforge.net"

#define DOWNLOAD_STRING "\
Autoupdate completed."

#define DOWNLOAD_ASK "Really update?"

#define DOWNLOAD_STRING_ERR "\
Update failed, retry later.\n\
\n\
Possible causes:\n\
- This computer is disconnected from the network\n\
- FreePOPs website is down\n\
- No write permissions on the updated files"

#define DOWNLOAD_TITLE "Update"

#define NEWS_TITLE "News"

#define NO_NEWS_STRING "No news"

#define GET_NEWS_ERROR "\
Unable to download news, retry later.\n\
\n\
Possible causes:\n\
- This computer is disconnected from the network\n\
- FreePOPs website is down"
