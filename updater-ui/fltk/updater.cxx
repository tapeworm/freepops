// generated by Fast Light User Interface Designer (fluid) version 1.0107

#include <libintl.h>
#include "updater.h"
#include <lua.hpp>
#include "linker.h"
#include <Fl/fl_message.H>
bool updater_fast_quit;
static void quit_program(void);
static void automata_next(void);

Fl_Double_Window *updater_main_win=(Fl_Double_Window *)0;

static void cb_updater_main_win(Fl_Double_Window*, void*) {
  quit_program();
}

Fl_Wizard *updater_wiz_main=(Fl_Wizard *)0;

Fl_Group *updater_grp_page_html=(Fl_Group *)0;

Fl_Help_View *updater_hlp_page_html=(Fl_Help_View *)0;

Fl_Group *updater_grp_page_select=(Fl_Group *)0;

Fl_Check_Browser *updater_chkbrw_select=(Fl_Check_Browser *)0;

Fl_Group *updater_grp_page_download=(Fl_Group *)0;

Fl_Progress *updater_prg_page_download=(Fl_Progress *)0;

Fl_Button *updater_btn_quit=(Fl_Button *)0;

static void cb_updater_btn_quit(Fl_Button*, void*) {
  quit_program();
}

Fl_Button *updater_btn_next=(Fl_Button *)0;

static void cb_updater_btn_next(Fl_Button*, void*) {
  automata_next();
}

Fl_Box *updater_box_logo=(Fl_Box *)0;

Fl_Box *updater_box_title=(Fl_Box *)0;

Fl_Double_Window* make_main_window() {
  Fl_Double_Window* w;
  { Fl_Double_Window* o = updater_main_win = new Fl_Double_Window(600, 400, gettext("FreePOPs updater"));
    w = o;
    o->callback((Fl_Callback*)cb_updater_main_win);
    { Fl_Wizard* o = updater_wiz_main = new Fl_Wizard(10, 80, 580, 270);
      { Fl_Group* o = updater_grp_page_html = new Fl_Group(20, 90, 564, 250);
        updater_hlp_page_html = new Fl_Help_View(20, 90, 560, 250);
        o->end();
      }
      { Fl_Group* o = updater_grp_page_select = new Fl_Group(20, 90, 560, 250);
        o->align(65);
        o->hide();
        { Fl_Check_Browser* o = updater_chkbrw_select = new Fl_Check_Browser(20, 110, 560, 225, gettext("Select the modules to update"));
          o->type(3);
          o->labelfont(2);
          o->labelsize(16);
          o->align(FL_ALIGN_TOP);
        }
        o->end();
      }
      { Fl_Group* o = updater_grp_page_download = new Fl_Group(20, 90, 560, 250);
        o->labelsize(16);
        o->hide();
        { Fl_Progress* o = updater_prg_page_download = new Fl_Progress(50, 200, 500, 30, gettext("Downloading: plugin list"));
          o->box(FL_THIN_DOWN_BOX);
          o->labelfont(2);
          o->labelsize(16);
          o->align(FL_ALIGN_TOP_LEFT);
        }
        o->end();
      }
      o->end();
    }
    { Fl_Button* o = updater_btn_quit = new Fl_Button(10, 360, 110, 30, gettext("Quit"));
      o->callback((Fl_Callback*)cb_updater_btn_quit);
      o->align(FL_ALIGN_CLIP);
    }
    { Fl_Button* o = updater_btn_next = new Fl_Button(480, 360, 110, 30, gettext("Next   @->"));
      o->shortcut(0xff0d);
      o->callback((Fl_Callback*)cb_updater_btn_next);
      o->align(FL_ALIGN_CLIP);
    }
    { Fl_Group* o = new Fl_Group(0, 0, 600, 70);
      o->box(FL_FLAT_BOX);
      o->color(FL_BACKGROUND2_COLOR);
      updater_box_logo = new Fl_Box(0, 0, 190, 70);
      { Fl_Box* o = updater_box_title = new Fl_Box(210, 10, 380, 50, gettext("Step 0 / Welcome"));
        o->labelfont(1);
        o->labelsize(20);
        o->align(68|FL_ALIGN_INSIDE);
      }
      o->end();
    }
    o->end();
  }
  return w;
}
#define PAGE_DOWNLOAD updater_grp_page_download
#define PAGE_HTML updater_grp_page_html
#define PAGE_SELECT updater_grp_page_select

static void lock() {
  updater_btn_next->deactivate();
updater_btn_quit->deactivate();
}

static void unlock() {
  updater_btn_next->activate();
updater_btn_quit->activate();
}

void updater_failure() {
  updater_btn_next->deactivate();
updater_btn_next->hide();
updater_btn_quit->activate();
updater_fast_quit = true;
}

static void automata_next() {
  static int updater_state = 0;
int n_states = 5;
Fl_Group* pages[] = {
	PAGE_HTML, PAGE_DOWNLOAD, PAGE_SELECT, PAGE_DOWNLOAD, PAGE_HTML
};
const char * titles[] = {
	gettext("Step 0 / Welcome"),
	gettext("Step 1 / Metadata download"),
	gettext("Step 2 / Selection"),
	gettext("Step 3 / Update"),
	gettext("Step 4 / Report"),
};

updater_state = (updater_state + 1) % n_states;

updater_wiz_main->value(pages[updater_state]);
updater_box_title->label(titles[updater_state]);

if (updater_state == 1) {
	lock();	
	updater_download_metadata(); 
	automata_next();
	unlock();
} 
if (updater_state == 3) {
	lock(); 
	updater_download(); 
	//if (updater_chkbrw_select->nchecked() == 0)
		automata_next();
	unlock();
} 
if (updater_state == 4) {
	// it is not a failure but it behaves the same way
	updater_failure();
}
}

static void quit_program() {
  if (updater_fast_quit || 
    fl_choice(gettext("Update not yet completed.\nDo you really want to quit?"),gettext("No"),gettext("Yes, quit!"),NULL)) {
	updater_main_win->hide();
	delete updater_main_win;
}
}
