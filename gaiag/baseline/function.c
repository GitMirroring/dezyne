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

#include "function.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>





typedef struct {int size;void (*f)(I*);function* self;} args_i_c;
typedef struct {int size;void (*f)(I*);function* self;} args_i_d;


typedef struct {int size;void (*f)(function*);function* self;} args_i_a;
typedef struct {int size;void (*f)(function*);function* self;} args_i_b;


static void helper_i_c(void* args) {
	args_i_c *a = args;
	a->f(a->self->i);
}

static void helper_i_d(void* args) {
	args_i_d *a = args;
	a->f(a->self->i);
}



static void helper_i_a(void* args) {
	args_i_a *a = args;
	a->f(a->self);
}

static void helper_i_b(void* args) {
	args_i_b *a = args;
	a->f(a->self);
}



static void toggle(function* self);


static void toggle(function* self) {
	(void)self;
	if (self->f) {
		self->i->out.c(self->i);
	}
	self->f = !(self->f);
}


static void i_a(function* self) {
	(void)self;
	if (true) {
		{
			toggle (self);
		}
	}
}

static void i_b(function* self) {
	(void)self;
	if (true) {
		{
			toggle (self);
			toggle (self);
			self->i->out.d(self->i);
		}
	}
}

static void call_in_i_a(I* self) {
	runtime_trace_in(&self->in, &self->out, "a");
	args_i_a a = {sizeof(args_i_a), i_a, self->in.self};
	runtime_event(helper_i_a, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_i_b(I* self) {
	runtime_trace_in(&self->in, &self->out, "b");
	args_i_b a = {sizeof(args_i_b), i_b, self->in.self};
	runtime_event(helper_i_b, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void function_init (function* self, locator* dezyne_locator, meta *m) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	memcpy(&self->m, m, sizeof(meta));
	self->f = false;
	self->i = &self->i_;
	self->i->in.a = call_in_i_a;
	self->i->in.b = call_in_i_b;
	self->i->in.name = "i";
	self->i->in.self = self;
}
