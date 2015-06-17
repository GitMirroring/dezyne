// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "MachineConstants.h"

#include "imotor.h"
#include "ilight.h"
#include "itouch.h"
#include "itimer_impl.h"
#include "timer.h"


#include "LegoBallSorter.h"

#include "runtime.h"
#include "locator.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>

typedef struct { } GtkLego;
void gtk_lego_update ()
{
}
    
typedef struct
{
  //: public itimer_impl
  struct {
    char const* name;
    void* self;
    void (*create)(itimer_impl* self,uint32_t ms);
    void (*cancel)(itimer_impl* self);
    
  } in;
  
  struct {
    char const* name;
    void* self;
    void (*timeout) (itimer_impl* self);
    
  } out;

  guint connection;
  itimer* port;
  GtkLego* lego;
} timer_impl;

void
timer_impl_init (timer_impl* self, locator* loc)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);

  self->in.name = "timer.in";
  self->in.self = 0;
  self->out.name = "itimer.out";
  self->out.self = 0;

  //self->connection = 0xdeadbeef;
  self->connection = 12345;
  self->port = locator_get (loc, "timer.port");
  self->lego = locator_get (loc, "lego");
}

bool
timer_impl_stupid_member (timer_impl* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  //fprintf (stderr, "%p: %d\n", self, self->connection);
  gtk_lego_update (self->lego);
  self->port->out.timeout (self->port);
  return false;
}

void
timer_impl_create (itimer_impl* self, int ms)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  timer_impl* t = (timer_impl*)self;
  t->connection = g_timeout_add (ms, (GSourceFunc)timer_impl_stupid_member, (gpointer)self);
  //fprintf (stderr, "%p: %d\n", t, t->connection);
}

void
timer_impl_cancel (itimer_impl* self)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  timer_impl* t = (timer_impl*)self;
  //fprintf (stderr, "%p: %d\n", t, t->connection);
  g_source_remove (t->connection);
}

timer_impl*
create_timer_impl (locator* loc)
{
  //fprintf (stderr, "%s\n", __FUNCTION__);
  timer_impl *t = (timer_impl*)malloc (sizeof (timer_impl));
  timer_impl_init (t, loc);
  return t;
}


typedef struct {
	void (*f)(void*);
	void *self;
} closure;

map* global_event_map;

static bool relaxed = true;

char* read_line() {
	char *line = 0;
	size_t size;
	if (getline(&line, &size, stdin) != -1) {
		if (strlen(line) > 1 && line[strlen(line)-1] == '\n') {
			line[strlen(line)-1] = 0;
		}
		return line;
	}
	return 0;
}

char* drop_prefix(char* string, char* prefix) {
	size_t len = strlen(prefix);
	if (strlen(string) >= len && !strncmp(string, prefix, len)) {
		return string + len;
	}
	return string;
}

char* consume_synchronous_out_events(map* event_map) {
	read_line();
	char* line;
	while ((line = read_line()) != 0) {
		void *p = 0;
		if (map_get(event_map, line, &p)) break;
		closure *c = p;
		c->f(c->self);
		free(line);
	}
	return line;
}

void log_in(char* prefix, char* event, map* event_map) {
	fprintf(stderr, "%s%s\n", prefix, event);
	if (relaxed) return;
	consume_synchronous_out_events(event_map);
	fprintf(stderr, "%s%s\n", prefix, "return");
}

void log_out(char* prefix, char* event, map* event_map) {
	(void)event_map;
	fprintf(stderr, "%s%s\n", prefix, event);
}

int log_valued(char* prefix, char* event, map* event_map, int (*string_to_value)(char*), char* (*value_to_string)(int))
{
	fprintf(stderr, "%s%s\n", prefix, event);
	if (relaxed) return 0;
	char* s = consume_synchronous_out_events(event_map);
	int r = string_to_value(drop_prefix(s, prefix));
	if ((int)r != -1) {
		fprintf(stderr, "%s%s\n", prefix, value_to_string(r));
		return r;
	}
	return 0;
}




void LegoBallSorter_log_event_ctrl_out_calibrated(IHandle* m) {
	(void)m;
	log_out("ctrl.", "calibrated", global_event_map);}
void LegoBallSorter_log_event_ctrl_out_finished(IHandle* m) {
	(void)m;
	log_out("ctrl.", "finished", global_event_map);}
void LegoBallSorter_log_event_brick1_aA_in_move(imotor* m) {
	(void)m;
	log_in("brick1_aA.", "move", global_event_map);}
void LegoBallSorter_log_event_brick1_aA_in_run(imotor* m) {
	(void)m;
	log_in("brick1_aA.", "run", global_event_map);}
void LegoBallSorter_log_event_brick1_aA_in_stop(imotor* m) {
	(void)m;
	log_in("brick1_aA.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick1_aA_in_coast(imotor* m) {
	(void)m;
	log_in("brick1_aA.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick1_aA_in_zero(imotor* m) {
	(void)m;
	log_in("brick1_aA.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick1_aA_in_position(imotor* m) {
	(void)m;
	log_in("brick1_aA.", "position", global_event_map);}
int LegoBallSorter_log_event_brick1_aA_in_at(imotor* m) {
	(void)m;
	return log_valued("brick1_aA.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
void LegoBallSorter_log_event_brick1_aB_in_move(imotor* m) {
	(void)m;
	log_in("brick1_aB.", "move", global_event_map);}
void LegoBallSorter_log_event_brick1_aB_in_run(imotor* m) {
	(void)m;
	log_in("brick1_aB.", "run", global_event_map);}
void LegoBallSorter_log_event_brick1_aB_in_stop(imotor* m) {
	(void)m;
	log_in("brick1_aB.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick1_aB_in_coast(imotor* m) {
	(void)m;
	log_in("brick1_aB.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick1_aB_in_zero(imotor* m) {
	(void)m;
	log_in("brick1_aB.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick1_aB_in_position(imotor* m) {
	(void)m;
	log_in("brick1_aB.", "position", global_event_map);}
int LegoBallSorter_log_event_brick1_aB_in_at(imotor* m) {
	(void)m;
	return log_valued("brick1_aB.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
void LegoBallSorter_log_event_brick1_aC_in_move(imotor* m) {
	(void)m;
	log_in("brick1_aC.", "move", global_event_map);}
void LegoBallSorter_log_event_brick1_aC_in_run(imotor* m) {
	(void)m;
	log_in("brick1_aC.", "run", global_event_map);}
void LegoBallSorter_log_event_brick1_aC_in_stop(imotor* m) {
	(void)m;
	log_in("brick1_aC.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick1_aC_in_coast(imotor* m) {
	(void)m;
	log_in("brick1_aC.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick1_aC_in_zero(imotor* m) {
	(void)m;
	log_in("brick1_aC.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick1_aC_in_position(imotor* m) {
	(void)m;
	log_in("brick1_aC.", "position", global_event_map);}
int LegoBallSorter_log_event_brick1_aC_in_at(imotor* m) {
	(void)m;
	return log_valued("brick1_aC.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
int LegoBallSorter_log_event_brick1_s1_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick1_s1.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
int LegoBallSorter_log_event_brick1_s2_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick1_s2.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
int LegoBallSorter_log_event_brick1_s3_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick1_s3.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
int LegoBallSorter_log_event_brick1_s4_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick1_s4.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
void LegoBallSorter_log_event_brick2_aA_in_move(imotor* m) {
	(void)m;
	log_in("brick2_aA.", "move", global_event_map);}
void LegoBallSorter_log_event_brick2_aA_in_run(imotor* m) {
	(void)m;
	log_in("brick2_aA.", "run", global_event_map);}
void LegoBallSorter_log_event_brick2_aA_in_stop(imotor* m) {
	(void)m;
	log_in("brick2_aA.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick2_aA_in_coast(imotor* m) {
	(void)m;
	log_in("brick2_aA.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick2_aA_in_zero(imotor* m) {
	(void)m;
	log_in("brick2_aA.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick2_aA_in_position(imotor* m) {
	(void)m;
	log_in("brick2_aA.", "position", global_event_map);}
int LegoBallSorter_log_event_brick2_aA_in_at(imotor* m) {
	(void)m;
	return log_valued("brick2_aA.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
void LegoBallSorter_log_event_brick2_aB_in_move(imotor* m) {
	(void)m;
	log_in("brick2_aB.", "move", global_event_map);}
void LegoBallSorter_log_event_brick2_aB_in_run(imotor* m) {
	(void)m;
	log_in("brick2_aB.", "run", global_event_map);}
void LegoBallSorter_log_event_brick2_aB_in_stop(imotor* m) {
	(void)m;
	log_in("brick2_aB.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick2_aB_in_coast(imotor* m) {
	(void)m;
	log_in("brick2_aB.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick2_aB_in_zero(imotor* m) {
	(void)m;
	log_in("brick2_aB.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick2_aB_in_position(imotor* m) {
	(void)m;
	log_in("brick2_aB.", "position", global_event_map);}
int LegoBallSorter_log_event_brick2_aB_in_at(imotor* m) {
	(void)m;
	return log_valued("brick2_aB.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
int LegoBallSorter_log_event_brick2_s2_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick2_s2.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
int LegoBallSorter_log_event_brick2_s3_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick2_s3.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
int LegoBallSorter_log_event_brick2_s4_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick2_s4.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
void LegoBallSorter_log_event_brick3_aA_in_move(imotor* m) {
	(void)m;
	log_in("brick3_aA.", "move", global_event_map);}
void LegoBallSorter_log_event_brick3_aA_in_run(imotor* m) {
	(void)m;
	log_in("brick3_aA.", "run", global_event_map);}
void LegoBallSorter_log_event_brick3_aA_in_stop(imotor* m) {
	(void)m;
	log_in("brick3_aA.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick3_aA_in_coast(imotor* m) {
	(void)m;
	log_in("brick3_aA.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick3_aA_in_zero(imotor* m) {
	(void)m;
	log_in("brick3_aA.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick3_aA_in_position(imotor* m) {
	(void)m;
	log_in("brick3_aA.", "position", global_event_map);}
int LegoBallSorter_log_event_brick3_aA_in_at(imotor* m) {
	(void)m;
	return log_valued("brick3_aA.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
void LegoBallSorter_log_event_brick3_aC_in_move(imotor* m) {
	(void)m;
	log_in("brick3_aC.", "move", global_event_map);}
void LegoBallSorter_log_event_brick3_aC_in_run(imotor* m) {
	(void)m;
	log_in("brick3_aC.", "run", global_event_map);}
void LegoBallSorter_log_event_brick3_aC_in_stop(imotor* m) {
	(void)m;
	log_in("brick3_aC.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick3_aC_in_coast(imotor* m) {
	(void)m;
	log_in("brick3_aC.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick3_aC_in_zero(imotor* m) {
	(void)m;
	log_in("brick3_aC.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick3_aC_in_position(imotor* m) {
	(void)m;
	log_in("brick3_aC.", "position", global_event_map);}
int LegoBallSorter_log_event_brick3_aC_in_at(imotor* m) {
	(void)m;
	return log_valued("brick3_aC.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
void LegoBallSorter_log_event_brick3_s1_in_turnon(ilight* m) {
	(void)m;
	log_in("brick3_s1.", "turnon", global_event_map);}
void LegoBallSorter_log_event_brick3_s1_in_turnoff(ilight* m) {
	(void)m;
	log_in("brick3_s1.", "turnoff", global_event_map);}
int LegoBallSorter_log_event_brick3_s1_in_detect(ilight* m) {
	(void)m;
	return log_valued("brick3_s1.", "detect", global_event_map, string_to_ilight_status, ilight_status_to_string);}
int LegoBallSorter_log_event_brick3_s2_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick3_s2.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
int LegoBallSorter_log_event_brick3_s3_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick3_s3.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
void LegoBallSorter_log_event_brick4_aA_in_move(imotor* m) {
	(void)m;
	log_in("brick4_aA.", "move", global_event_map);}
void LegoBallSorter_log_event_brick4_aA_in_run(imotor* m) {
	(void)m;
	log_in("brick4_aA.", "run", global_event_map);}
void LegoBallSorter_log_event_brick4_aA_in_stop(imotor* m) {
	(void)m;
	log_in("brick4_aA.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick4_aA_in_coast(imotor* m) {
	(void)m;
	log_in("brick4_aA.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick4_aA_in_zero(imotor* m) {
	(void)m;
	log_in("brick4_aA.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick4_aA_in_position(imotor* m) {
	(void)m;
	log_in("brick4_aA.", "position", global_event_map);}
int LegoBallSorter_log_event_brick4_aA_in_at(imotor* m) {
	(void)m;
	return log_valued("brick4_aA.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
void LegoBallSorter_log_event_brick4_aB_in_move(imotor* m) {
	(void)m;
	log_in("brick4_aB.", "move", global_event_map);}
void LegoBallSorter_log_event_brick4_aB_in_run(imotor* m) {
	(void)m;
	log_in("brick4_aB.", "run", global_event_map);}
void LegoBallSorter_log_event_brick4_aB_in_stop(imotor* m) {
	(void)m;
	log_in("brick4_aB.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick4_aB_in_coast(imotor* m) {
	(void)m;
	log_in("brick4_aB.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick4_aB_in_zero(imotor* m) {
	(void)m;
	log_in("brick4_aB.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick4_aB_in_position(imotor* m) {
	(void)m;
	log_in("brick4_aB.", "position", global_event_map);}
int LegoBallSorter_log_event_brick4_aB_in_at(imotor* m) {
	(void)m;
	return log_valued("brick4_aB.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
void LegoBallSorter_log_event_brick4_aC_in_move(imotor* m) {
	(void)m;
	log_in("brick4_aC.", "move", global_event_map);}
void LegoBallSorter_log_event_brick4_aC_in_run(imotor* m) {
	(void)m;
	log_in("brick4_aC.", "run", global_event_map);}
void LegoBallSorter_log_event_brick4_aC_in_stop(imotor* m) {
	(void)m;
	log_in("brick4_aC.", "stop", global_event_map);}
void LegoBallSorter_log_event_brick4_aC_in_coast(imotor* m) {
	(void)m;
	log_in("brick4_aC.", "coast", global_event_map);}
void LegoBallSorter_log_event_brick4_aC_in_zero(imotor* m) {
	(void)m;
	log_in("brick4_aC.", "zero", global_event_map);}
void LegoBallSorter_log_event_brick4_aC_in_position(imotor* m) {
	(void)m;
	log_in("brick4_aC.", "position", global_event_map);}
int LegoBallSorter_log_event_brick4_aC_in_at(imotor* m) {
	(void)m;
	return log_valued("brick4_aC.", "at", global_event_map, string_to_imotor_result_t, imotor_result_t_to_string);}
int LegoBallSorter_log_event_brick4_s1_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick4_s1.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
int LegoBallSorter_log_event_brick4_s2_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick4_s2.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}
int LegoBallSorter_log_event_brick4_s3_in_detect(itouch* m) {
	(void)m;
	return log_valued("brick4_s3.", "detect", global_event_map, string_to_itouch_status, itouch_status_to_string);}

void LegoBallSorter_fill_event_map(LegoBallSorter* m, map* e) {
	int dzn_i = 0;
	void *p;
	closure *c;
	m->ctrl->out.calibrated = LegoBallSorter_log_event_ctrl_out_calibrated;
	m->ctrl->out.finished = LegoBallSorter_log_event_ctrl_out_finished;
	m->brick1_aA->in.move = LegoBallSorter_log_event_brick1_aA_in_move;
	m->brick1_aA->in.run = LegoBallSorter_log_event_brick1_aA_in_run;
	m->brick1_aA->in.stop = LegoBallSorter_log_event_brick1_aA_in_stop;
	m->brick1_aA->in.coast = LegoBallSorter_log_event_brick1_aA_in_coast;
	m->brick1_aA->in.zero = LegoBallSorter_log_event_brick1_aA_in_zero;
	m->brick1_aA->in.position = LegoBallSorter_log_event_brick1_aA_in_position;
	m->brick1_aA->in.at = LegoBallSorter_log_event_brick1_aA_in_at;
	m->brick1_aB->in.move = LegoBallSorter_log_event_brick1_aB_in_move;
	m->brick1_aB->in.run = LegoBallSorter_log_event_brick1_aB_in_run;
	m->brick1_aB->in.stop = LegoBallSorter_log_event_brick1_aB_in_stop;
	m->brick1_aB->in.coast = LegoBallSorter_log_event_brick1_aB_in_coast;
	m->brick1_aB->in.zero = LegoBallSorter_log_event_brick1_aB_in_zero;
	m->brick1_aB->in.position = LegoBallSorter_log_event_brick1_aB_in_position;
	m->brick1_aB->in.at = LegoBallSorter_log_event_brick1_aB_in_at;
	m->brick1_aC->in.move = LegoBallSorter_log_event_brick1_aC_in_move;
	m->brick1_aC->in.run = LegoBallSorter_log_event_brick1_aC_in_run;
	m->brick1_aC->in.stop = LegoBallSorter_log_event_brick1_aC_in_stop;
	m->brick1_aC->in.coast = LegoBallSorter_log_event_brick1_aC_in_coast;
	m->brick1_aC->in.zero = LegoBallSorter_log_event_brick1_aC_in_zero;
	m->brick1_aC->in.position = LegoBallSorter_log_event_brick1_aC_in_position;
	m->brick1_aC->in.at = LegoBallSorter_log_event_brick1_aC_in_at;
	m->brick1_s1->in.detect = LegoBallSorter_log_event_brick1_s1_in_detect;
	m->brick1_s2->in.detect = LegoBallSorter_log_event_brick1_s2_in_detect;
	m->brick1_s3->in.detect = LegoBallSorter_log_event_brick1_s3_in_detect;
	m->brick1_s4->in.detect = LegoBallSorter_log_event_brick1_s4_in_detect;
	m->brick2_aA->in.move = LegoBallSorter_log_event_brick2_aA_in_move;
	m->brick2_aA->in.run = LegoBallSorter_log_event_brick2_aA_in_run;
	m->brick2_aA->in.stop = LegoBallSorter_log_event_brick2_aA_in_stop;
	m->brick2_aA->in.coast = LegoBallSorter_log_event_brick2_aA_in_coast;
	m->brick2_aA->in.zero = LegoBallSorter_log_event_brick2_aA_in_zero;
	m->brick2_aA->in.position = LegoBallSorter_log_event_brick2_aA_in_position;
	m->brick2_aA->in.at = LegoBallSorter_log_event_brick2_aA_in_at;
	m->brick2_aB->in.move = LegoBallSorter_log_event_brick2_aB_in_move;
	m->brick2_aB->in.run = LegoBallSorter_log_event_brick2_aB_in_run;
	m->brick2_aB->in.stop = LegoBallSorter_log_event_brick2_aB_in_stop;
	m->brick2_aB->in.coast = LegoBallSorter_log_event_brick2_aB_in_coast;
	m->brick2_aB->in.zero = LegoBallSorter_log_event_brick2_aB_in_zero;
	m->brick2_aB->in.position = LegoBallSorter_log_event_brick2_aB_in_position;
	m->brick2_aB->in.at = LegoBallSorter_log_event_brick2_aB_in_at;
	m->brick2_s2->in.detect = LegoBallSorter_log_event_brick2_s2_in_detect;
	m->brick2_s3->in.detect = LegoBallSorter_log_event_brick2_s3_in_detect;
	m->brick2_s4->in.detect = LegoBallSorter_log_event_brick2_s4_in_detect;
	m->brick3_aA->in.move = LegoBallSorter_log_event_brick3_aA_in_move;
	m->brick3_aA->in.run = LegoBallSorter_log_event_brick3_aA_in_run;
	m->brick3_aA->in.stop = LegoBallSorter_log_event_brick3_aA_in_stop;
	m->brick3_aA->in.coast = LegoBallSorter_log_event_brick3_aA_in_coast;
	m->brick3_aA->in.zero = LegoBallSorter_log_event_brick3_aA_in_zero;
	m->brick3_aA->in.position = LegoBallSorter_log_event_brick3_aA_in_position;
	m->brick3_aA->in.at = LegoBallSorter_log_event_brick3_aA_in_at;
	m->brick3_aC->in.move = LegoBallSorter_log_event_brick3_aC_in_move;
	m->brick3_aC->in.run = LegoBallSorter_log_event_brick3_aC_in_run;
	m->brick3_aC->in.stop = LegoBallSorter_log_event_brick3_aC_in_stop;
	m->brick3_aC->in.coast = LegoBallSorter_log_event_brick3_aC_in_coast;
	m->brick3_aC->in.zero = LegoBallSorter_log_event_brick3_aC_in_zero;
	m->brick3_aC->in.position = LegoBallSorter_log_event_brick3_aC_in_position;
	m->brick3_aC->in.at = LegoBallSorter_log_event_brick3_aC_in_at;
	m->brick3_s1->in.turnon = LegoBallSorter_log_event_brick3_s1_in_turnon;
	m->brick3_s1->in.turnoff = LegoBallSorter_log_event_brick3_s1_in_turnoff;
	m->brick3_s1->in.detect = LegoBallSorter_log_event_brick3_s1_in_detect;
	m->brick3_s2->in.detect = LegoBallSorter_log_event_brick3_s2_in_detect;
	m->brick3_s3->in.detect = LegoBallSorter_log_event_brick3_s3_in_detect;
	m->brick4_aA->in.move = LegoBallSorter_log_event_brick4_aA_in_move;
	m->brick4_aA->in.run = LegoBallSorter_log_event_brick4_aA_in_run;
	m->brick4_aA->in.stop = LegoBallSorter_log_event_brick4_aA_in_stop;
	m->brick4_aA->in.coast = LegoBallSorter_log_event_brick4_aA_in_coast;
	m->brick4_aA->in.zero = LegoBallSorter_log_event_brick4_aA_in_zero;
	m->brick4_aA->in.position = LegoBallSorter_log_event_brick4_aA_in_position;
	m->brick4_aA->in.at = LegoBallSorter_log_event_brick4_aA_in_at;
	m->brick4_aB->in.move = LegoBallSorter_log_event_brick4_aB_in_move;
	m->brick4_aB->in.run = LegoBallSorter_log_event_brick4_aB_in_run;
	m->brick4_aB->in.stop = LegoBallSorter_log_event_brick4_aB_in_stop;
	m->brick4_aB->in.coast = LegoBallSorter_log_event_brick4_aB_in_coast;
	m->brick4_aB->in.zero = LegoBallSorter_log_event_brick4_aB_in_zero;
	m->brick4_aB->in.position = LegoBallSorter_log_event_brick4_aB_in_position;
	m->brick4_aB->in.at = LegoBallSorter_log_event_brick4_aB_in_at;
	m->brick4_aC->in.move = LegoBallSorter_log_event_brick4_aC_in_move;
	m->brick4_aC->in.run = LegoBallSorter_log_event_brick4_aC_in_run;
	m->brick4_aC->in.stop = LegoBallSorter_log_event_brick4_aC_in_stop;
	m->brick4_aC->in.coast = LegoBallSorter_log_event_brick4_aC_in_coast;
	m->brick4_aC->in.zero = LegoBallSorter_log_event_brick4_aC_in_zero;
	m->brick4_aC->in.position = LegoBallSorter_log_event_brick4_aC_in_position;
	m->brick4_aC->in.at = LegoBallSorter_log_event_brick4_aC_in_at;
	m->brick4_s1->in.detect = LegoBallSorter_log_event_brick4_s1_in_detect;
	m->brick4_s2->in.detect = LegoBallSorter_log_event_brick4_s2_in_detect;
	m->brick4_s3->in.detect = LegoBallSorter_log_event_brick4_s3_in_detect;

	c = malloc(sizeof (closure));
	c->f = (void (*))m->ctrl->in.calibrate;
	c->self = m->ctrl;
	map_put(e, "ctrl.calibrate", c);
	c = malloc(sizeof (closure));
	c->f = (void (*))m->ctrl->in.stop;
	c->self = m->ctrl;
	map_put(e, "ctrl.stop", c);
	c = malloc(sizeof (closure));
	c->f = (void (*))m->ctrl->in.operate;
	c->self = m->ctrl;
	map_put(e, "ctrl.operate", c);
}

void illegal_print() {
	fputs("illegal\n", stderr);
	exit(0);
}

int main() {
	runtime dezyne_runtime;
	runtime_init(&dezyne_runtime);
	locator dezyne_locator;
	locator_init(&dezyne_locator, &dezyne_runtime);
	dezyne_locator.illegal = illegal_print;

	locator_set (&dezyne_locator, "timer.create", create_timer_impl);

	LegoBallSorter sut;
	dzn_meta_t mt = {"sut", 0};
	LegoBallSorter_init(&sut, &dezyne_locator, &mt);

	map event_map;
	map_init(&event_map);
	global_event_map = &event_map;
	LegoBallSorter_fill_event_map(&sut, &event_map);

	char* line;
	while ((line = read_line()) != 0) {
		void *p = 0;
		if (!map_get(&event_map, line, &p)) {
			closure *c = p;
			c->f(c->self);
		}
		free(line);
	}
	return 0;
}
