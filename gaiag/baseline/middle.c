// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "middle.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>





typedef struct {int size;void (*f)(itop*);middle* self;} args_t_f;


typedef struct {int size;void (*f)(middle*);middle* self;} args_t_e;
typedef struct {int size;void (*f)(middle*);middle* self;} args_b_f;


static void helper_t_f(void* args) {
	args_t_f *a = args;
	a->f(a->self->t);
}



static void helper_t_e(void* args) {
	args_t_e *a = args;
	a->f(a->self);
}

static void helper_b_f(void* args) {
	args_b_f *a = args;
	a->f(a->self);
}







static void t_e(middle* self) {
	(void)self;
	{
		self->l->in.log(self->l);
		self->b->in.e(self->b);
	}
}

static void b_f(middle* self) {
	(void)self;
	{
		self->l->in.log(self->l);
		self->t->out.f(self->t);
	}
}

static void call_in_t_e(itop* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_t_e a = {sizeof(args_t_e), t_e, self->in.self};
	runtime_event(helper_t_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_out_b_f(ibottom* self) {
	runtime_trace_out(&self->in, &self->out, "f");
	args_b_f a = {sizeof(args_b_f), b_f, self->out.self};
	component *c = self->out.self;
	runtime_defer(self->in.self, self->out.self, helper_b_f, &a);
}


void middle_init (middle* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->l = locator_get(dezyne_locator, "ilogger");

	self->t = &self->t_;
	self->t->in.e = call_in_t_e;
	self->t->in.name = "t";
	self->t->in.self = self;
	self->t->out.name = "";
	self->t->out.self = 0;
	self->b = &self->b_;
	self->b->in.name = "";
	self->b->in.self = 0;
	self->b->out.name = "b";
	self->b->out.self = self;
	self->b->out.f = call_out_b_f;
	self->l->out.name = "l";
	self->l->out.self = self;
}
