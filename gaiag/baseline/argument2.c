// Dezyne --- Dezyne command line tools
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

#include "argument2.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>





typedef struct {int size;void (*f)(I*);argument2* self;} args_i_f;


typedef struct {int size;void (*f)(argument2*);argument2* self;} args_i_e;


static void helper_i_f(void* args) {
	args_i_f *a = args;
	a->f(a->self->i);
}



static void helper_i_e(void* args) {
	args_i_e *a = args;
	a->f(a->self);
}



static bool g(argument2* self,bool ga, bool gb);


static bool g(argument2* self,bool ga, bool gb) {
	(void)self;
	self->i->out.f(self->i);
	return (ga || gb);
}


static void i_e(argument2* self) {
	(void)self;
	if (true) {
		self->b = !(self->b);
		bool c = g(self, self->b, self->b);
		self->b = g(self, c, c);
		if (c) {
			self->i->out.f(self->i);
		}
	}
}

static void call_in_i_e(I* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_i_e a = {sizeof(args_i_e), i_e, self->in.self};
	runtime_event(helper_i_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void argument2_init (argument2* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->b = false;
	self->i = &self->i_;
	self->i->in.e = call_in_i_e;
	self->i->in.name = "i";
	self->i->in.self = self;
	self->i->out.name = "";
	self->i->out.self = 0;
}
