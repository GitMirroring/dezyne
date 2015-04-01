// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
#include <string.h>



typedef enum {
	imperative_States_I, imperative_States_II, imperative_States_III, imperative_States_IV
} imperative_States;


typedef struct {int size;void (*f)(iimperative*);imperative* self;} args_i_f;
typedef struct {int size;void (*f)(iimperative*);imperative* self;} args_i_g;
typedef struct {int size;void (*f)(iimperative*);imperative* self;} args_i_h;


typedef struct {int size;void (*f)(imperative*);imperative* self;} args_i_e;


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







static void i_e(imperative* self) {
	(void)self;
	if (self->state == imperative_States_I) {
		self->i->out.f(self->i);
		self->i->out.g(self->i);
		self->i->out.h(self->i);
		self->state = imperative_States_II;
	}
	else if (self->state == imperative_States_II) {
		self->state = imperative_States_III;
	}
	else if (self->state == imperative_States_III) {
		self->i->out.f(self->i);
		self->i->out.g(self->i);
		self->i->out.g(self->i);
		self->i->out.f(self->i);
		self->state = imperative_States_IV;
	}
	else if (self->state == imperative_States_IV) {
		self->i->out.h(self->i);
		self->state = imperative_States_I;
	}
}

static void call_in_i_e(iimperative* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_i_e a = {sizeof(args_i_e), i_e, self->in.self};
	runtime_event(helper_i_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void imperative_init (imperative* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->state = imperative_States_I;
	self->i = &self->i_;
	self->i->in.e = call_in_i_e;
	self->i->in.name = "i";
	self->i->in.self = self;
	self->i->out.name = "";
	self->i->out.self = 0;
}
