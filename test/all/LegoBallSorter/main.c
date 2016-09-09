// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

/* -*-c-style:linux;indent-tabs-mode:t-*- */

#include <assert.h>
#include <dzn/runtime.h>
#include <dzn/locator.h>
#include <dzn/map.h>

#include "LegoBallSorter.h"

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
	void (*f)(void*);
	void *self;
} closure;

typedef struct {
	runtime_info* info;
	char* name;
} args_flush;

map* global_event_map;
bool global_flush_p;

static bool relaxed = false;

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

char* consume_synchronous_out_events(char* prefix, char* event, map* event_map) {
	char* s;
	char match[1024];
	strcat(strcpy(match, prefix), event);
	while ((s = read_line()) != 0) if (!strcmp(match, s)) break;
	while ((s = read_line()) != 0) {
		void *p = 0;
		if (map_get(event_map, s, &p)) break;
		closure *c = p;
		c->f(c->self);
		free(s);
	}
	return s ? s : "";
}

void log_in(char* prefix, char* event, map* event_map) {
	fprintf(stderr, "%s%s\n", prefix, event);
	if (relaxed) return;
	consume_synchronous_out_events(prefix, event, event_map);
	fprintf(stderr, "%s%s\n", prefix, "return");
}

void log_out(char* prefix, char* event, map* event_map) {
	(void)event_map;
	fprintf(stderr, "%s%s\n", prefix, event);
}

void log_flush(void* args) {
	args_flush* a = args;
	fprintf(stderr, "%s.<flush>\n", a->name);
	runtime_flush(a->info);
}

int log_valued(char* prefix, char* event, map* event_map, int (*string_to_value)(char*), char* (*value_to_string)(int))
{
	fprintf(stderr, "%s%s\n", prefix, event);
	if (relaxed) return 0;
	char* s = consume_synchronous_out_events(prefix, event, event_map);
	int r = string_to_value(drop_prefix(s, prefix));
	if ((int)r != INT_MIN) {
		fprintf(stderr, "%s%s\n", prefix, value_to_string(r));
		return r;
	}
	fprintf(stderr,"\"%s\": is not a reply value\n", s);
	assert(!"not a reply value");
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
	args_flush* args;

	component *comp = calloc(1, sizeof (component));
	comp->dzn_info.performs_flush = global_flush_p;
	comp->dzn_meta.parent = 0;
	comp->dzn_meta.name = "<external>";

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
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "ctrl";
	c->self = args;

	m->ctrl->meta.requires.port = "ctrl";
	m->ctrl->meta.requires.address = comp;
	m->ctrl->meta.requires.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "ctrl.<flush>", c);

	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick1_aA";
	c->self = args;

	m->brick1_aA->meta.provides.port = "brick1_aA";
	m->brick1_aA->meta.provides.address = comp;
	m->brick1_aA->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick1_aA.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick1_aB";
	c->self = args;

	m->brick1_aB->meta.provides.port = "brick1_aB";
	m->brick1_aB->meta.provides.address = comp;
	m->brick1_aB->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick1_aB.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick1_aC";
	c->self = args;

	m->brick1_aC->meta.provides.port = "brick1_aC";
	m->brick1_aC->meta.provides.address = comp;
	m->brick1_aC->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick1_aC.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick1_s1";
	c->self = args;

	m->brick1_s1->meta.provides.port = "brick1_s1";
	m->brick1_s1->meta.provides.address = comp;
	m->brick1_s1->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick1_s1.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick1_s2";
	c->self = args;

	m->brick1_s2->meta.provides.port = "brick1_s2";
	m->brick1_s2->meta.provides.address = comp;
	m->brick1_s2->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick1_s2.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick1_s3";
	c->self = args;

	m->brick1_s3->meta.provides.port = "brick1_s3";
	m->brick1_s3->meta.provides.address = comp;
	m->brick1_s3->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick1_s3.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick1_s4";
	c->self = args;

	m->brick1_s4->meta.provides.port = "brick1_s4";
	m->brick1_s4->meta.provides.address = comp;
	m->brick1_s4->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick1_s4.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick2_aA";
	c->self = args;

	m->brick2_aA->meta.provides.port = "brick2_aA";
	m->brick2_aA->meta.provides.address = comp;
	m->brick2_aA->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick2_aA.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick2_aB";
	c->self = args;

	m->brick2_aB->meta.provides.port = "brick2_aB";
	m->brick2_aB->meta.provides.address = comp;
	m->brick2_aB->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick2_aB.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick2_s2";
	c->self = args;

	m->brick2_s2->meta.provides.port = "brick2_s2";
	m->brick2_s2->meta.provides.address = comp;
	m->brick2_s2->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick2_s2.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick2_s3";
	c->self = args;

	m->brick2_s3->meta.provides.port = "brick2_s3";
	m->brick2_s3->meta.provides.address = comp;
	m->brick2_s3->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick2_s3.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick2_s4";
	c->self = args;

	m->brick2_s4->meta.provides.port = "brick2_s4";
	m->brick2_s4->meta.provides.address = comp;
	m->brick2_s4->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick2_s4.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick3_aA";
	c->self = args;

	m->brick3_aA->meta.provides.port = "brick3_aA";
	m->brick3_aA->meta.provides.address = comp;
	m->brick3_aA->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick3_aA.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick3_aC";
	c->self = args;

	m->brick3_aC->meta.provides.port = "brick3_aC";
	m->brick3_aC->meta.provides.address = comp;
	m->brick3_aC->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick3_aC.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick3_s1";
	c->self = args;

	m->brick3_s1->meta.provides.port = "brick3_s1";
	m->brick3_s1->meta.provides.address = comp;
	m->brick3_s1->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick3_s1.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick3_s2";
	c->self = args;

	m->brick3_s2->meta.provides.port = "brick3_s2";
	m->brick3_s2->meta.provides.address = comp;
	m->brick3_s2->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick3_s2.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick3_s3";
	c->self = args;

	m->brick3_s3->meta.provides.port = "brick3_s3";
	m->brick3_s3->meta.provides.address = comp;
	m->brick3_s3->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick3_s3.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick4_aA";
	c->self = args;

	m->brick4_aA->meta.provides.port = "brick4_aA";
	m->brick4_aA->meta.provides.address = comp;
	m->brick4_aA->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick4_aA.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick4_aB";
	c->self = args;

	m->brick4_aB->meta.provides.port = "brick4_aB";
	m->brick4_aB->meta.provides.address = comp;
	m->brick4_aB->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick4_aB.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick4_aC";
	c->self = args;

	m->brick4_aC->meta.provides.port = "brick4_aC";
	m->brick4_aC->meta.provides.address = comp;
	m->brick4_aC->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick4_aC.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick4_s1";
	c->self = args;

	m->brick4_s1->meta.provides.port = "brick4_s1";
	m->brick4_s1->meta.provides.address = comp;
	m->brick4_s1->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick4_s1.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick4_s2";
	c->self = args;

	m->brick4_s2->meta.provides.port = "brick4_s2";
	m->brick4_s2->meta.provides.address = comp;
	m->brick4_s2->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick4_s2.<flush>", c);
	c = malloc(sizeof (closure));
	c->f = log_flush;
	args = malloc(sizeof(args_flush));
	args->info = &comp->dzn_info;
	args->name = "brick4_s3";
	c->self = args;

	m->brick4_s3->meta.provides.port = "brick4_s3";
	m->brick4_s3->meta.provides.address = comp;
	m->brick4_s3->meta.provides.meta = &comp->dzn_meta;

	{
		if (global_flush_p) {
			comp->dzn_meta.name = "<internal>";
		}
	}
	map_put(e, "brick4_s3.<flush>", c);

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

int main(int argc, char** argv) {
	global_flush_p = argc > 1 && !strcmp(argv[1], "--flush");
	runtime dezyne_runtime;
	runtime_init(&dezyne_runtime);
	locator dezyne_locator;
	locator_init(&dezyne_locator, &dezyne_runtime);
	dezyne_locator.illegal = illegal_print;

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
