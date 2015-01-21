// Dezyne --- Dezyne command line tools
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

#include "function.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {function* self;} args_i_c;
typedef struct {function* self;} args_i_d;


static void opaque_i_c(void* args) {
	args_i_c *a = args;
	void (*f)(void*) = a->self->i->out.c;
	f(a->self->i);
}

static void opaque_i_d(void* args) {
	args_i_d *a = args;
	void (*f)(void*) = a->self->i->out.d;
	f(a->self->i);
}



static void internal_i_a(void* self_) {
	function* self = self_;
	(void)self;
	DZN_LOG("function.i_a");
	if (true) {
		toggle (self);
	}
}

static void internal_i_b(void* self_) {
	function* self = self_;
	(void)self;
	DZN_LOG("function.i_b");
	if (true) {
		toggle (self);
		toggle (self);
		{
			args_i_d a = {self};
			args_i_d* p = malloc(sizeof(args_i_d));
			memcpy (p, &a, sizeof(args_i_d));
			runtime_defer(self->rt, self, opaque_i_d, p);
		}
	}
}

static void opaque_i_a(void* a) {
	typedef struct {function* self;} args;
	args* b = a;
	internal_i_a(b->self);
}

static void opaque_i_b(void* a) {
	typedef struct {function* self;} args;
	args* b = a;
	internal_i_b(b->self);
}

static void i_a(void* self_) {
	function* self = ((I*)self_)->in.self;
	typedef struct {function* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_i_a, a);
}

static void i_b(void* self_) {
	function* self = ((I*)self_)->in.self;
	typedef struct {function* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_i_b, a);
}

void toggle(function* self) {
	(void)self;
	if (self->f) {
		{
			args_i_c a = {self};
			args_i_c* p = malloc(sizeof(args_i_c));
			memcpy (p, &a, sizeof(args_i_c));
			runtime_defer(self->rt, self, opaque_i_c, p);
		}
	}
	self->f = !(self->f);
}

void function_init (function* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->f = false;
	self->i = &self->i_;
	self->i->in.a = i_a;
	self->i->in.b = i_b;
	self->i->in.self = self;
}
