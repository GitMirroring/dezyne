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

#include "Adaptor.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>



typedef enum {
	Adaptor_State_Idle, Adaptor_State_Active, Adaptor_State_Terminating
} Adaptor_State;




typedef struct {int size;void (*f)(Adaptor*);Adaptor* self;} args_runner_run;
typedef struct {int size;void (*f)(Adaptor*);Adaptor* self;} args_choice_a;




static void helper_runner_run(void* args) {
	args_runner_run *a = args;
	a->f(a->self);
}

static void helper_choice_a(void* args) {
	args_choice_a *a = args;
	a->f(a->self);
}







static void runner_run(Adaptor* self) {
	(void)self;
	if (self->state == Adaptor_State_Idle && self->count < 2) {
		self->choice->in.e(self->choice);
		self->state = Adaptor_State_Active;
	}
	else if (self->state == Adaptor_State_Idle && !(self->count < 2)) {
	}
	else if (self->state == Adaptor_State_Active) {
		{
		}
	}
	else if (self->state == Adaptor_State_Terminating) {
	}
}

static void choice_a(Adaptor* self) {
	(void)self;
	if (self->state == Adaptor_State_Idle) {
	}
	else if (self->state == Adaptor_State_Active) {
		{
			self->count = self->count + 1;
			self->choice->in.e(self->choice);
			self->state = Adaptor_State_Terminating;
		}
	}
	else if (self->state == Adaptor_State_Terminating && self->count < 2) {
		self->choice->in.e(self->choice);
		self->state = Adaptor_State_Active;
	}
	else if (self->state == Adaptor_State_Terminating && !(self->count < 2)) self->state = Adaptor_State_Idle;
}

static void call_in_runner_run(IRun* self) {
	runtime_trace_in(&self->in, &self->out, "run");
	args_runner_run a = {sizeof(args_runner_run), runner_run, self->in.self};
	runtime_event(helper_runner_run, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_out_choice_a(IChoice* self) {
	runtime_trace_out(&self->in, &self->out, "a");
	args_choice_a a = {sizeof(args_choice_a), choice_a, self->out.self};
	component *c = self->out.self;
	runtime_defer(self->in.self, self->out.self, helper_choice_a, &a);
}


void Adaptor_init (Adaptor* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->state = Adaptor_State_Idle;
	self->count = 0;
	self->runner = &self->runner_;
	self->runner->in.run = call_in_runner_run;
	self->runner->in.name = "runner";
	self->runner->in.self = self;
	self->runner->out.name = "";
	self->runner->out.self = 0;
	self->choice = &self->choice_;
	self->choice->in.name = "";
	self->choice->in.self = 0;
	self->choice->out.name = "choice";
	self->choice->out.self = self;
	self->choice->out.a = call_out_choice_a;
}
