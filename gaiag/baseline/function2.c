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

#include "function2.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {void (*f)(void*); function2* self;} args_i_c;
typedef struct {void (*f)(void*); function2* self;} args_i_d;


typedef struct {void (*f)(void*); function2* self;} args_i_a;
typedef struct {void (*f)(void*); function2* self;} args_i_b;


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



static bool vtoggle(function2* self);


static bool vtoggle(function2* self) {
	(void)self;
	if (self->f) {
		args_i_c a = {self->i->out.c,self};
		args_i_c* p = malloc(sizeof(args_i_c));
		memcpy(p, &a, sizeof(args_i_c));
		runtime_defer(self->rt, self, helper_i_c, p);
	}
	return !(self->f);
}


static void i_a(void* self_) {
	function2* self = self_;
	(void)self;
	DZN_LOG("function2.i_a");
	if (true) {
		self->f = vtoggle (self);
	}
}

static void i_b(void* self_) {
	function2* self = self_;
	(void)self;
	DZN_LOG("function2.i_b");
	if (true) {
		self->f = vtoggle (self);
		bool bb = vtoggle (self);
		self->f = bb;
		{
			args_i_d a = {self->i->out.d,self};
			args_i_d* p = malloc(sizeof(args_i_d));
			memcpy(p, &a, sizeof(args_i_d));
			runtime_defer(self->rt, self, helper_i_d, p);
		}
	}
}

static void callback_i_a(void* self_) {
	function2* self = ((ifunction2*)self_)->in.self;
	args_i_a* a = malloc(sizeof(args_i_a));
	a->f=i_a;
	a->self=self;
	runtime_event(helper_i_a, a);
}

static void callback_i_b(void* self_) {
	function2* self = ((ifunction2*)self_)->in.self;
	args_i_b* a = malloc(sizeof(args_i_b));
	a->f=i_b;
	a->self=self;
	runtime_event(helper_i_b, a);
}


void function2_init (function2* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->f = false;
	self->i = &self->i_;
	self->i->in.a = callback_i_a;
	self->i->in.b = callback_i_b;
	self->i->in.self = self;
}
