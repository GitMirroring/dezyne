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

#include "If.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>





typedef struct {int size;void (*f)(I*);If* self;} args_i_b;
typedef struct {int size;void (*f)(I*);If* self;} args_i_c;


typedef struct {int size;void (*f)(If*);If* self;} args_i_a;


static void helper_i_b(void* args) {
	args_i_b *a = args;
	a->f(a->self->i);
}

static void helper_i_c(void* args) {
	args_i_c *a = args;
	a->f(a->self->i);
}



static void helper_i_a(void* args) {
	args_i_a *a = args;
	a->f(a->self);
}







static void i_a(If* self) {
	(void)self;
	{
		if (self->t) {
			self->i->out.b(self->i);
		}
		else {
			self->i->out.c(self->i);
		}
		self->t = !(self->t);
	}
}

static void call_in_i_a(I* self) {
	runtime_trace_in(&self->in, &self->out, "a");
	args_i_a a = {sizeof(args_i_a), i_a, self->in.self};
	runtime_event(helper_i_a, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void If_init (If* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->t = false;
	self->i = &self->i_;
	self->i->in.a = call_in_i_a;
	self->i->in.name = "i";
	self->i->in.self = self;
	self->i->out.name = "";
	self->i->out.self = 0;
}
