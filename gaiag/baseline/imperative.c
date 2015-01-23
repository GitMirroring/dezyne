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

#include "imperative.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
	imperative_States_I, imperative_States_II, imperative_States_III, imperative_States_IV
} imperative_States;


typedef struct {void (*f)(void*); imperative* self;} args_i_f;
typedef struct {void (*f)(void*); imperative* self;} args_i_g;
typedef struct {void (*f)(void*); imperative* self;} args_i_h;


typedef struct {void (*f)(void*); imperative* self;} args_i_e;


static void helper_i_f(void* args) {
	args_i_f *a = args;
	a->f(a->self->i);
}

static void helper_i_g(void* args) {
	args_i_g *a = args;
	a->f(a->self->i);
}

static void helper_i_h(void* args) {
	args_i_h *a = args;
	a->f(a->self->i);
}



static void helper_i_e(void* args) {
	args_i_e *a = args;
	a->f(a->self);
}







static void i_e(void* self_) {
	imperative* self = self_;
	(void)self;
	DZN_LOG("imperative.i_e");
	if (self->state == imperative_States_I) {
		{
			args_i_f a = {self->i->out.f,self};
			args_i_f* p = malloc(sizeof(args_i_f));
			memcpy(p, &a, sizeof(args_i_f));
			runtime_defer(self->rt, self, helper_i_f, p);
		}
		{
			args_i_g a = {self->i->out.g,self};
			args_i_g* p = malloc(sizeof(args_i_g));
			memcpy(p, &a, sizeof(args_i_g));
			runtime_defer(self->rt, self, helper_i_g, p);
		}
		{
			args_i_h a = {self->i->out.h,self};
			args_i_h* p = malloc(sizeof(args_i_h));
			memcpy(p, &a, sizeof(args_i_h));
			runtime_defer(self->rt, self, helper_i_h, p);
		}
		self->state = imperative_States_II;
	}
	else if (self->state == imperative_States_II) {
		self->state = imperative_States_III;
	}
	else if (self->state == imperative_States_III) {
		{
			args_i_f a = {self->i->out.f,self};
			args_i_f* p = malloc(sizeof(args_i_f));
			memcpy(p, &a, sizeof(args_i_f));
			runtime_defer(self->rt, self, helper_i_f, p);
		}
		{
			args_i_g a = {self->i->out.g,self};
			args_i_g* p = malloc(sizeof(args_i_g));
			memcpy(p, &a, sizeof(args_i_g));
			runtime_defer(self->rt, self, helper_i_g, p);
		}
		{
			args_i_g a = {self->i->out.g,self};
			args_i_g* p = malloc(sizeof(args_i_g));
			memcpy(p, &a, sizeof(args_i_g));
			runtime_defer(self->rt, self, helper_i_g, p);
		}
		{
			args_i_f a = {self->i->out.f,self};
			args_i_f* p = malloc(sizeof(args_i_f));
			memcpy(p, &a, sizeof(args_i_f));
			runtime_defer(self->rt, self, helper_i_f, p);
		}
		self->state = imperative_States_IV;
	}
	else if (self->state == imperative_States_IV) {
		{
			args_i_h a = {self->i->out.h,self};
			args_i_h* p = malloc(sizeof(args_i_h));
			memcpy(p, &a, sizeof(args_i_h));
			runtime_defer(self->rt, self, helper_i_h, p);
		}
		self->state = imperative_States_I;
	}
}

static void callback_i_e(void* self_) {
	imperative* self = ((iimperative*)self_)->in.self;
	args_i_e* a = malloc(sizeof(args_i_e));
	a->f=i_e;
	a->self=self;
	runtime_event(helper_i_e, a);
}


void imperative_init (imperative* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->state = imperative_States_I;
	self->i = &self->i_;
	self->i->in.e = callback_i_e;
	self->i->in.self = self;
}
