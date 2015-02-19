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

#include "Guardthreetopon.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(IGuardthreetopon*);Guardthreetopon* self;} args_i_a;


typedef struct {int size;void (*f)(Guardthreetopon*);Guardthreetopon* self;} args_i_e;
typedef struct {int size;void (*f)(Guardthreetopon*);Guardthreetopon* self;} args_i_t;
typedef struct {int size;void (*f)(Guardthreetopon*);Guardthreetopon* self;} args_i_s;
typedef struct {int size;void (*f)(Guardthreetopon*);Guardthreetopon* self;} args_r_a;


static void helper_i_a(void* args) {
	args_i_a *a = args;
	a->f(a->self->i);
}



static void helper_i_e(void* args) {
	args_i_e *a = args;
	a->f(a->self);
}

static void helper_i_t(void* args) {
	args_i_t *a = args;
	a->f(a->self);
}

static void helper_i_s(void* args) {
	args_i_s *a = args;
	a->f(a->self);
}

static void helper_r_a(void* args) {
	args_r_a *a = args;
	a->f(a->self);
}







static void i_e(Guardthreetopon* self) {
	(void)self;
	DZN_LOG("Guardthreetopon.i_e");
	if (true && self->b) {
		{
			args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
			runtime_defer(self->rt, self, helper_i_a, &a);
		}
	}
	else if (true && !(self->b)) {
		bool c = true;
		if (c) {
			args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
			runtime_defer(self->rt, self, helper_i_a, &a);
		}
	}
}

static void i_t(Guardthreetopon* self) {
	(void)self;
	DZN_LOG("Guardthreetopon.i_t");
	if (self->b) {
		args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
		runtime_defer(self->rt, self, helper_i_a, &a);
	}
	else if (!(self->b)) {
		args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
		runtime_defer(self->rt, self, helper_i_a, &a);
	}
}

static void i_s(Guardthreetopon* self) {
	(void)self;
	DZN_LOG("Guardthreetopon.i_s");
	{
		args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
		runtime_defer(self->rt, self, helper_i_a, &a);
	}
}

static void r_a(Guardthreetopon* self) {
	(void)self;
	DZN_LOG("Guardthreetopon.r_a");
	{
	}
}

static void callback_i_e(IGuardthreetopon* self) {
	args_i_e a = {sizeof(args_i_e), i_e, self->in.self};
	runtime_event(helper_i_e, &a);
}

static void callback_i_t(IGuardthreetopon* self) {
	args_i_t a = {sizeof(args_i_t), i_t, self->in.self};
	runtime_event(helper_i_t, &a);
}

static void callback_i_s(IGuardthreetopon* self) {
	args_i_s a = {sizeof(args_i_s), i_s, self->in.self};
	runtime_event(helper_i_s, &a);
}

static void callback_r_a(RGuardthreetopon* self) {
	args_r_a a = {sizeof(args_r_a), r_a, self->out.self};
	runtime_event(helper_r_a, &a);
}


void Guardthreetopon_init (Guardthreetopon* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->b = false;
	self->i = &self->i_;
	self->i->in.e = callback_i_e;
	self->i->in.t = callback_i_t;
	self->i->in.s = callback_i_s;
	self->i->in.self = self;
	self->r = &self->r_;
	self->r->out.self = self;
	self->r->out.a = callback_r_a;
}
