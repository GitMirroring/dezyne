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

#include "Twotopon.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(ITwotopon*);Twotopon* self;} args_i_a;


typedef struct {int size;void (*f)(Twotopon*);Twotopon* self;} args_i_e;
typedef struct {int size;void (*f)(Twotopon*);Twotopon* self;} args_i_t;


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







static void i_e(Twotopon* self) {
	(void)self;
	DZN_LOG("Twotopon.i_e");
	if (self->b) {
		{
			args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
			runtime_defer(&self->sub, helper_i_a, &a);
		}
	}
	else if (!(self->b)) {
		{
			args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
			runtime_defer(&self->sub, helper_i_a, &a);
		}
	}
}

static void i_t(Twotopon* self) {
	(void)self;
	DZN_LOG("Twotopon.i_t");
	{
		args_i_a a = {sizeof(args_i_a), self->i->out.a, self};
		runtime_defer(&self->sub, helper_i_a, &a);
	}
}

static void callback_i_e(ITwotopon* self) {
	args_i_e a = {sizeof(args_i_e), i_e, self->in.self};
	runtime_event(helper_i_e, &a);
}

static void callback_i_t(ITwotopon* self) {
	args_i_t a = {sizeof(args_i_t), i_t, self->in.self};
	runtime_event(helper_i_t, &a);
}


void Twotopon_init (Twotopon* self, locator* dezyne_locator) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	self->b = false;
	self->i = &self->i_;
	self->i->in.e = callback_i_e;
	self->i->in.t = callback_i_t;
	self->i->in.self = self;
}
