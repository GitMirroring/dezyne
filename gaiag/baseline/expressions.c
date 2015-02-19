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

#include "expressions.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(I*);expressions* self;} args_i_a;
typedef struct {int size;void (*f)(I*);expressions* self;} args_i_hi;
typedef struct {int size;void (*f)(I*);expressions* self;} args_i_lo;


typedef struct {int size;void (*f)(expressions*);expressions* self;} args_i_e;


static void helper_i_a(void* args) {
	args_i_a *a = args;
	a->f(a->self->i);
}

static void helper_i_hi(void* args) {
	args_i_hi *a = args;
	a->f(a->self->i);
}

static void helper_i_lo(void* args) {
	args_i_lo *a = args;
	a->f(a->self->i);
}



static void helper_i_e(void* args) {
	args_i_e *a = args;
	a->f(a->self);
}







static void i_e(expressions* self) {
	(void)self;
	DZN_LOG("expressions.i_e");
	if (true) {
		if (self->state == 0) {
			self->state = 3;
			{
				args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
				runtime_defer(self->rt, self, helper_i_a, &a);
			}
		}
		else {
			self->state = self->state - 1;
			if (self->c < self->state) {
				self->c = self->c + 1;
			}
			else {
				if (self->c <= (self->state + 1)) {
					{
						args_i_lo a = {sizeof(args_i_lo), self->i->out.lo, self};
						runtime_defer(self->rt, self, helper_i_lo, &a);
					}
				}
				else {
					if (self->c > self->state) {
						{
							args_i_hi a = {sizeof(args_i_hi), self->i->out.hi, self};
							runtime_defer(self->rt, self, helper_i_hi, &a);
						}
					}
				}
			}
		}
	}
}

static void callback_i_e(I* self) {
	args_i_e a = {sizeof(args_i_e), i_e, self->in.self};
	runtime_event(helper_i_e, &a);
}


void expressions_init (expressions* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->state = 3;
	self->c = 0;
	self->i = &self->i_;
	self->i->in.e = callback_i_e;
	self->i->in.self = self;
}
