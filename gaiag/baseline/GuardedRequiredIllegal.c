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

#include "GuardedRequiredIllegal.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(Top*);GuardedRequiredIllegal* self;} args_t_f;


typedef struct {int size;void (*f)(GuardedRequiredIllegal*);GuardedRequiredIllegal* self;} args_t_unguarded;
typedef struct {int size;void (*f)(GuardedRequiredIllegal*);GuardedRequiredIllegal* self;} args_t_e;
typedef struct {int size;void (*f)(GuardedRequiredIllegal*);GuardedRequiredIllegal* self;} args_b_f;


static void helper_t_f(void* args) {
	args_t_f *a = args;
	a->f(a->self->t);
}



static void helper_t_unguarded(void* args) {
	args_t_unguarded *a = args;
	a->f(a->self);
}

static void helper_t_e(void* args) {
	args_t_e *a = args;
	a->f(a->self);
}

static void helper_b_f(void* args) {
	args_b_f *a = args;
	a->f(a->self);
}







static void t_unguarded(GuardedRequiredIllegal* self) {
	(void)self;
	DZN_LOG("GuardedRequiredIllegal.t_unguarded");
	{
	}
}

static void t_e(GuardedRequiredIllegal* self) {
	(void)self;
	DZN_LOG("GuardedRequiredIllegal.t_e");
	if (!(self->c)) {
		self->c = true;
		self->b->in.e(self->b);
	}
	else if (self->c) {
	}
}

static void b_f(GuardedRequiredIllegal* self) {
	(void)self;
	DZN_LOG("GuardedRequiredIllegal.b_f");
	if (!(self->c)) assert(false);
	else if (self->c) {
		self->c = false;
	}
}

static void callback_t_unguarded(Top* self) {
	args_t_unguarded a = {sizeof(args_t_unguarded), t_unguarded, self->in.self};
	runtime_event(helper_t_unguarded, &a);
}

static void callback_t_e(Top* self) {
	args_t_e a = {sizeof(args_t_e), t_e, self->in.self};
	runtime_event(helper_t_e, &a);
}

static void callback_b_f(Bottom* self) {
	args_b_f a = {sizeof(args_b_f), b_f, self->out.self};
	runtime_event(helper_b_f, &a);
}


void GuardedRequiredIllegal_init (GuardedRequiredIllegal* self, locator* dezyne_locator) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	self->c = false;
	self->t = &self->t_;
	self->t->in.unguarded = callback_t_unguarded;
	self->t->in.e = callback_t_e;
	self->t->in.self = self;
	self->b = &self->b_;
	self->b->out.self = self;
	self->b->out.f = callback_b_f;
}
