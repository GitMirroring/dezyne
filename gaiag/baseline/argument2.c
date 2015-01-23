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

#include "argument2.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {void (*f)(void*); argument2* self;} args_i_f;


typedef struct {void (*f)(void*); argument2* self;} args_i_e;


static void helper_i_f(void* args) {
	args_i_f *a = args;
	a->f(a->self->i);
}



static void helper_i_e(void* args) {
	args_i_e *a = args;
	a->f(a->self);
}



static bool g(argument2* self, bool ga, bool gb);


static bool g(argument2* self, bool ga, bool gb) {
	(void)self;
	{
		args_i_f a = {self->i->out.f,self};
		args_i_f* p = malloc(sizeof(args_i_f));
		memcpy(p, &a, sizeof(args_i_f));
		runtime_defer(self->rt, self, helper_i_f, p);
	}
	return (ga || gb);
}


static void i_e(void* self_) {
	argument2* self = self_;
	(void)self;
	DZN_LOG("argument2.i_e");
	if (true) self->b = !(self->b);
	bool c = g(self, self->b, self->b);
	self->b = g(self, c, c);
	if (c) {
		{
			args_i_f a = {self->i->out.f,self};
			args_i_f* p = malloc(sizeof(args_i_f));
			memcpy(p, &a, sizeof(args_i_f));
			runtime_defer(self->rt, self, helper_i_f, p);
		}
	}
}

static void callback_i_e(void* self_) {
	argument2* self = ((I*)self_)->in.self;
	args_i_e* a = malloc(sizeof(args_i_e));
	a->f=i_e;
	a->self=self;
	runtime_event(helper_i_e, a);
}


void argument2_init (argument2* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->b = false;
	self->i = &self->i_;
	self->i->in.e = callback_i_e;
	self->i->in.self = self;
}
