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

#include "argument.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {argument* self;} args_i_f;


static void opaque_i_f(void* args) {
	args_i_f *a = args;
	void (*f)(void*) = a->self->i->out.f;
	f(a->self->i);
}



static void internal_i_e(void* self_) {
	argument* self = self_;
	(void)self;
	DZN_LOG("argument.i_e");
	if (true) self->b = !(self->b);
	bool c = g(self, self->b);
	self->b = g(self, c);
	if (c)
	{
		{
			args_i_f a = {self};
			args_i_f* p = malloc(sizeof(args_i_f));
			memcpy (p, &a, sizeof(args_i_f));
			runtime_defer(self->rt, self, opaque_i_f, p);
		}
	}
}

static void opaque_i_e(void* a) {
	typedef struct {argument* self;} args;
	args* b = a;
	internal_i_e(b->self);
}

static void i_e(void* self_) {
	argument* self = ((I*)self_)->in.self;
	typedef struct {argument* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_i_e, a);
}

bool g(argument* self, bool gc) {
	(void)self;
	{
		args_i_f a = {self};
		args_i_f* p = malloc(sizeof(args_i_f));
		memcpy (p, &a, sizeof(args_i_f));
		runtime_defer(self->rt, self, opaque_i_f, p);
	}
	return (gc || self->b);
}

void argument_init (argument* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->b = false;
	self->i = &self->i_;
	self->i->in.e = i_e;
	self->i->in.self = self;
}
