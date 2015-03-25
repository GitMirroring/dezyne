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

#include "sugar.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>



typedef enum {
	sugar_Enum_False, sugar_Enum_True
} sugar_Enum;


typedef struct {int size;void (*f)(I*);sugar* self;} args_i_a;


typedef struct {int size;void (*f)(sugar*);sugar* self;} args_i_e;


static void helper_i_a(void* args) {
	args_i_a *a = args;
	a->f(a->self->i);
}



static void helper_i_e(void* args) {
	args_i_e *a = args;
	a->f(a->self);
}







static void i_e(sugar* self) {
	(void)self;
	if (self->s == sugar_Enum_False) if (self->s == sugar_Enum_False)         self->i->out.a(self->i);
	else {
		int t = sugar_Enum_False;
		if (t == sugar_Enum_True)           self->i->out.a(self->i);
	}
}

static void call_in_i_e(I* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_i_e a = {sizeof(args_i_e), i_e, self->in.self};
	runtime_event(helper_i_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void sugar_init (sugar* self, locator* dezyne_locator, meta *m) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	memcpy(&self->m, m, sizeof(meta));
	self->s = sugar_Enum_False;
	self->i = &self->i_;
	self->i->in.e = call_in_i_e;
	self->i->in.name = "i";
	self->i->in.self = self;
}
