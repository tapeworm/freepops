#include <stdio.h>
#include <stdlib.h>

#include <FL/Fl.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Window.H>
#include <FL/fl_draw.H>

#ifdef MACOSX
        #include "getopt1.h"
#else
        #include <getopt.h>
#endif

#define min(a,b) ((a<b)?a:b)
#define max(a,b) ((a<b)?b:a)

static Fl_Box *icon,*msg;
static Fl_Window *win;
static Fl_Button *but_a;
static Fl_Button *but_b;
static const char *icon_label = "i";
static const char *but_a_label = "@returnarrow close";
static const char *but_b_label = NULL;
static const char *msg_label = NULL;
static int rc;

static void callback(Fl_Widget* x){
	if (x == but_a || x == win) rc = 2;
	if (x == but_b) rc = 4;
	win->hide();
}

static void make_window() {
	int msg_w, msg_h, used_w=0, used_h=0;
	fl_font(FL_HELVETICA, 14);

	win = new Fl_Window(410,113,"");

	if (but_a_label != NULL) {
		but_a = new Fl_Button(0, 0, 0, 0, but_a_label);
		but_a->shortcut("^[");
		but_a->align(FL_ALIGN_INSIDE|FL_ALIGN_WRAP);
		but_a->callback(callback);
		but_a->when(FL_WHEN_RELEASE);
		msg_w = msg_h = 0;
		fl_measure(but_a_label, msg_w, msg_h);
  		msg_w += 10; msg_h += 10;
		msg_h = msg_h * (msg_w / 200 + 1);
		msg_w = min (msg_w , 200 );
		but_a->resize(400 - msg_w - used_w, 103 - msg_h, msg_w, msg_h);
		used_w += 10 + msg_w;
		used_h = max (used_h , 10 + msg_h);
	}
	if (but_b_label != NULL) {
		but_b = new Fl_Button(0, 0, 0, 0, but_b_label);
		but_b->align(FL_ALIGN_INSIDE|FL_ALIGN_WRAP);
		but_b->callback(callback);
		but_b->when(FL_WHEN_RELEASE);
		msg_w = msg_h = 0;
		fl_measure(but_b_label, msg_w, msg_h);
  		msg_w += 10; msg_h += 10;
		msg_h = msg_h * (msg_w / 200 + 1);
		msg_w = min (msg_w , 200 );
		but_b->resize(400 - msg_w - used_w, 103 - msg_h, msg_w, msg_h);
		used_w += 10 + msg_w;
		used_h = max (used_h , 10 + msg_h);
	}
	if (icon_label != NULL) {
		icon = new Fl_Box(10, 10, 50, 50);
		icon->box(FL_THIN_UP_BOX);
		icon->labelfont(FL_TIMES_BOLD);
		icon->labelsize(34);
		icon->color(FL_WHITE);
		icon->labelcolor(FL_BLUE);
		icon->label(icon_label);
	}
	msg = new Fl_Box(60, 25, 340, 20);
	msg->align(FL_ALIGN_LEFT|FL_ALIGN_INSIDE|FL_ALIGN_WRAP);
	msg->label(msg_label);
	win->resizable(new Fl_Box(60,10,110-60,27));
	win->end();
	win->set_modal();
	win->hotspot(but_a_label?(Fl_Widget*)but_a:(Fl_Widget*)msg);
	win->callback(callback);
	win->border(0);
	win->show();
}

void usage(char *s){
	fprintf(stderr, "usage: %s [-a label] [-b label] [-i icon] msg\n\n",s);
	fprintf(stderr, "\tdefaults are:\n");
	fprintf(stderr, "\t\t-a %s\n",but_a_label?but_a_label:"NULL");
	fprintf(stderr, "\t\t-b %s\n",but_b_label?but_b_label:"NULL");
	fprintf(stderr, "\t\t-i %s\n",icon_label?icon_label:"NULL");
	fprintf(stderr, "\n\treturn:\n");
	fprintf(stderr, "\t\t1 on error\n");
	fprintf(stderr, "\t\t2 on button a press\n");
	fprintf(stderr, "\t\t4 on button b press\n");
}

int main(int argc, char**argv){
	int res;

	
	while ( (res=getopt(argc,argv,"a:b:i:"))!= -1){
		switch (res) {
			case 'a': but_a_label = optarg; break;
			case 'b': but_b_label = optarg; break;
			case 'i': icon_label = optarg; break;
			default: usage(argv[0]); return 1;
		}
	}

	if (optind >= argc){
		usage(argv[0]);
		return 1;
	}

	msg_label = argv[optind];

	make_window();

	Fl::run();

	return rc;
}
