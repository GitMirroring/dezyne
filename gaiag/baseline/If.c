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

#include "If.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(void*);If* self;} args_i_b;
typedef struct {int size;void (*f)(void*);If* self;} args_i_c;


typedef struct {int size;void (*f)(void*);If* self;} args_i_a;


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







static void i_a(void* self_) {
	If* self = self_;
	(void)self;
	DZN_LOG("If.i_a");
	if (self->t) {
		{
			args_i_b a = {sizeof(args_i_b), self->i->out.b, self};
			runtime_defer(self->rt, self, helper_i_b, &a);
		}
	}
	else {
		{
			args_i_c a = {sizeof(args_i_c), self->i->out.c, self};
			runtime_defer(self->rt, self, helper_i_c, &a);
		}
	}
	self->t = !(self->t);
}

static void callback_i_a(void* self_) {
	If* self = ((I*)self_)->in.self;
	args_i_a a = {sizeof(args_i_a), i_a, self};
	runtime_event(helper_i_a, &a);
}


void If_init (If* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->t = false;
	self->i = &self->i_;
	self->i->in.a = callback_i_a;
	self->i->in.self = self;
}
