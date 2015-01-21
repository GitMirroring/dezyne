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

#include "expressions.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {expressions* self;} args_i_a;
typedef struct {expressions* self;} args_i_hi;
typedef struct {expressions* self;} args_i_lo;


static void opaque_i_a(void* args) {
	args_i_a *a = args;
	void (*f)(void*) = a->self->i->out.a;
	f(a->self->i);
}

static void opaque_i_hi(void* args) {
	args_i_hi *a = args;
	void (*f)(void*) = a->self->i->out.hi;
	f(a->self->i);
}

static void opaque_i_lo(void* args) {
	args_i_lo *a = args;
	void (*f)(void*) = a->self->i->out.lo;
	f(a->self->i);
}



static void internal_i_e(void* self_) {
	expressions* self = self_;
	(void)self;
	DZN_LOG("expressions.i_e");
	if (true) if (self->state == 0)
	{
		self->state = 3;
		{
			args_i_a a = {self};
			args_i_a* p = malloc(sizeof(args_i_a));
			memcpy (p, &a, sizeof(args_i_a));
			runtime_defer(self->rt, self, opaque_i_a, p);
		}
	}
	else
	{
		self->state = self->state - 1;
		if (self->c < self->state)
		{
			self->c = self->c + 1;
		}
		else
		{
			if (self->c <= (self->state + 1))
			{
				{
					args_i_lo a = {self};
					args_i_lo* p = malloc(sizeof(args_i_lo));
					memcpy (p, &a, sizeof(args_i_lo));
					runtime_defer(self->rt, self, opaque_i_lo, p);
				}
			}
			else
			{
				if (self->c > self->state)
				{
					{
						args_i_hi a = {self};
						args_i_hi* p = malloc(sizeof(args_i_hi));
						memcpy (p, &a, sizeof(args_i_hi));
						runtime_defer(self->rt, self, opaque_i_hi, p);
					}
				}
			}
		}
	}
}

static void opaque_i_e(void* a) {
	typedef struct {expressions* self;} args;
	args* b = a;
	internal_i_e(b->self);
}

static void i_e(void* self_) {
	expressions* self = ((I*)self_)->in.self;
	typedef struct {expressions* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_i_e, a);
}


void expressions_init (expressions* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->state = 3;
	self->c = 0;
	self->i = &self->i_;
	self->i->in.e = i_e;
	self->i->in.self = self;
}
