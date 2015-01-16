// Dezyne --- Dezyne command line tools
//
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

#include "middle.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {middle* self;} args_t_f;


static void opaque_t_f(void* args) {
	args_t_f *a = args;
	void (*f)(void*) = a->self->t->out.f;
	f(a->self->t);
}



static void internal_t_e(void* self_) {
	middle* self = self_;
	(void)self;
	DZN_LOG("middle.t_e");
	self->l->in.log(self->l);
	self->b->in.e(self->b);
}

static void internal_b_f(void* self_) {
	middle* self = self_;
	(void)self;
	DZN_LOG("middle.b_f");
	self->l->in.log(self->l);
	{
		args_t_f a = {self};
		args_t_f* p = malloc(sizeof(args_t_f));
		memcpy (p, &a, sizeof(args_t_f));
		runtime_defer(self->rt, self, opaque_t_f, p);
	}
}

static void opaque_t_e(void* a) {
	typedef struct {middle* self;} args;
	args* b = a;
	internal_t_e(b->self);
}

static void opaque_b_f(void* a) {
	typedef struct {middle* self;} args;
	args* b = a;
	internal_b_f(b->self);
}

static void t_e(void* self_) {
	middle* self = ((itop*)self_)->in.self;
	typedef struct {middle* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_t_e, a);
}

static void b_f(void* self_) {
	middle* self = ((ibottom*)self_)->out.self;
	typedef struct {middle* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_b_f, a);
}


void middle_init (middle* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->l_ = *(ilogger*)locator_get(dezyne_locator, "ilogger");

	self->t = &self->t_;
	self->t->in.e = t_e;
	self->t->in.self = self;
	self->b = &self->b_;
	self->b->out.self = self;
	self->b->out.f = b_f;
	self->l = &self->l_;
	self->l->out.self = self;
}
