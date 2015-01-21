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

#include "If.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {If* self;} args_i_b;
typedef struct {If* self;} args_i_c;


static void opaque_i_b(void* args) {
	args_i_b *a = args;
	void (*f)(void*) = a->self->i->out.b;
	f(a->self->i);
}

static void opaque_i_c(void* args) {
	args_i_c *a = args;
	void (*f)(void*) = a->self->i->out.c;
	f(a->self->i);
}



static void internal_i_a(void* self_) {
	If* self = self_;
	(void)self;
	DZN_LOG("If.i_a");
	if (self->t)
	{
		{
			args_i_b a = {self};
			args_i_b* p = malloc(sizeof(args_i_b));
			memcpy (p, &a, sizeof(args_i_b));
			runtime_defer(self->rt, self, opaque_i_b, p);
		}
	}
	else
	{
		{
			args_i_c a = {self};
			args_i_c* p = malloc(sizeof(args_i_c));
			memcpy (p, &a, sizeof(args_i_c));
			runtime_defer(self->rt, self, opaque_i_c, p);
		}
	}
	self->t = !(self->t);
}

static void opaque_i_a(void* a) {
	typedef struct {If* self;} args;
	args* b = a;
	internal_i_a(b->self);
}

static void i_a(void* self_) {
	If* self = ((I*)self_)->in.self;
	typedef struct {If* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_i_a, a);
}


void If_init (If* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->t = false;
	self->i = &self->i_;
	self->i->in.a = i_a;
	self->i->in.self = self;
}
