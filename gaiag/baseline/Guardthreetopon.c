// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
#include <string.h>





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
	if (true && self->b) {
		self->i->out.a(self->i);
	}
	else if (true && !(self->b)) {
		bool c = true;
		if (c)         self->i->out.a(self->i);
	}
}

static void i_t(Guardthreetopon* self) {
	(void)self;
	if (self->b)       self->i->out.a(self->i);
	else if (!(self->b))       self->i->out.a(self->i);
}

static void i_s(Guardthreetopon* self) {
	(void)self;
	self->i->out.a(self->i);
}

static void r_a(Guardthreetopon* self) {
	(void)self;
	{
	}
}

static void call_in_i_e(IGuardthreetopon* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_i_e a = {sizeof(args_i_e), i_e, self->in.self};
	runtime_event(helper_i_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_i_t(IGuardthreetopon* self) {
	runtime_trace_in(&self->in, &self->out, "t");
	args_i_t a = {sizeof(args_i_t), i_t, self->in.self};
	runtime_event(helper_i_t, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_in_i_s(IGuardthreetopon* self) {
	runtime_trace_in(&self->in, &self->out, "s");
	args_i_s a = {sizeof(args_i_s), i_s, self->in.self};
	runtime_event(helper_i_s, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_out_r_a(RGuardthreetopon* self) {
	runtime_trace_out(&self->in, &self->out, "a");
	args_r_a a = {sizeof(args_r_a), r_a, self->out.self};
	component *c = self->out.self;
	runtime_defer(self->in.self, self->out.self, helper_r_a, &a);
}


void Guardthreetopon_init (Guardthreetopon* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->b = false;
	self->i = &self->i_;
	self->i->in.e = call_in_i_e;
	self->i->in.t = call_in_i_t;
	self->i->in.s = call_in_i_s;
	self->i->in.name = "i";
	self->i->in.self = self;
	self->i->out.name = "";
	self->i->out.self = 0;
	self->r = &self->r_;
	self->r->in.name = "";
	self->r->in.self = 0;
	self->r->out.name = "r";
	self->r->out.self = self;
	self->r->out.a = call_out_r_a;
}
