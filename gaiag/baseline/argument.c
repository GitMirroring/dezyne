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

#include "argument.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(void*);argument* self;} args_i_f;


typedef struct {int size;void (*f)(void*);argument* self;} args_i_e;


static void helper_i_f(void* args) {
	args_i_f *a = args;
	a->f(a->self->i);
}



static void helper_i_e(void* args) {
	args_i_e *a = args;
	a->f(a->self);
}



static bool g(argument* self, bool gc);


static bool g(argument* self, bool gc) {
	(void)self;
	{
		args_i_f a = {sizeof(args_i_f), self->i->out.f, self};
		runtime_defer(self->rt, self, helper_i_f, &a);
	}
	return (gc || self->b);
}


static void i_e(void* self_) {
	argument* self = self_;
	(void)self;
	DZN_LOG("argument.i_e");
	if (true) self->b = !(self->b);
	bool c = g(self, self->b);
	self->b = g(self, c);
	if (c) {
		{
			args_i_f a = {sizeof(args_i_f), self->i->out.f, self};
			runtime_defer(self->rt, self, helper_i_f, &a);
		}
	}
}

static void callback_i_e(void* self_) {
	argument* self = ((I*)self_)->in.self;
	args_i_e a = {sizeof(args_i_e), i_e, self};
	runtime_event(helper_i_e, &a);
}


void argument_init (argument* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->b = false;
	self->i = &self->i_;
	self->i->in.e = callback_i_e;
	self->i->in.self = self;
}
