// Dezyne --- Dezyne command line tools
//
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

#include "middle.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {void (*f)(void*); middle* self;} args_t_f;


typedef struct {void (*f)(void*); middle* self;} args_t_e;
typedef struct {void (*f)(void*); middle* self;} args_b_f;


static void helper_t_f(void* args) {
	args_t_f *a = args;
	a->f(a->self->t);
}



static void helper_t_e(void* args) {
	args_t_e *a = args;
	a->f(a->self);
}

static void helper_b_f(void* args) {
	args_b_f *a = args;
	a->f(a->self);
}







static void t_e(void* self_) {
	middle* self = self_;
	(void)self;
	DZN_LOG("middle.t_e");
	self->l->in.log(self->l);
	self->b->in.e(self->b);
}

static void b_f(void* self_) {
	middle* self = self_;
	(void)self;
	DZN_LOG("middle.b_f");
	self->l->in.log(self->l);
	{
		args_t_f a = {self->t->out.f,self};
		args_t_f* p = malloc(sizeof(args_t_f));
		memcpy(p, &a, sizeof(args_t_f));
		runtime_defer(self->rt, self, helper_t_f, p);
	}
}

static void callback_t_e(void* self_) {
	middle* self = ((itop*)self_)->in.self;
	args_t_e* a = malloc(sizeof(args_t_e));
	a->f=t_e;
	a->self=self;
	runtime_event(helper_t_e, a);
}

static void callback_b_f(void* self_) {
	middle* self = ((ibottom*)self_)->out.self;
	args_b_f* a = malloc(sizeof(args_b_f));
	a->f=b_f;
	a->self=self;
	runtime_event(helper_b_f, a);
}


void middle_init (middle* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->l_ = *(ilogger*)locator_get(dezyne_locator, "ilogger");

	self->t = &self->t_;
	self->t->in.e = callback_t_e;
	self->t->in.self = self;
	self->b = &self->b_;
	self->b->out.self = self;
	self->b->out.f = callback_b_f;
	self->l = &self->l_;
	self->l->out.self = self;
}
