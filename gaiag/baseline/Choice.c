// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "Choice.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>



typedef enum {
	Choice_State_Off, Choice_State_Idle, Choice_State_Busy
} Choice_State;


typedef struct {int size;void (*f)(IChoice*);Choice* self;} args_c_a;


typedef struct {int size;void (*f)(Choice*);Choice* self;} args_c_e;


static void helper_c_a(void* args) {
	args_c_a *a = args;
	a->f(a->self->c);
}



static void helper_c_e(void* args) {
	args_c_e *a = args;
	a->f(a->self);
}







static void c_e(Choice* self) {
	(void)self;
	if (self->s == Choice_State_Off) {
		self->s = Choice_State_Idle;
		self->c->out.a(self->c);
	}
	else if (self->s == Choice_State_Idle) {
		self->s = Choice_State_Busy;
		self->c->out.a(self->c);
	}
	else if (self->s == Choice_State_Busy) {
		self->s = Choice_State_Idle;
		self->c->out.a(self->c);
	}
}

static void call_in_c_e(IChoice* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_c_e a = {sizeof(args_c_e), c_e, self->in.self};
	runtime_event(helper_c_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void Choice_init (Choice* self, locator* dezyne_locator, meta *m) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	memcpy(&self->m, m, sizeof(meta));
	self->s = Choice_State_Off;
	self->c = &self->c_;
	self->c->in.e = call_in_c_e;
	self->c->in.name = "c";
	self->c->in.self = self;
}
