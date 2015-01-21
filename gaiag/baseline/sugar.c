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

#include "sugar.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
	sugar_Enum_False, sugar_Enum_True
} sugar_Enum;


typedef struct {sugar* self;} args_i_a;


static void opaque_i_a(void* args) {
	args_i_a *a = args;
	void (*f)(void*) = a->self->i->out.a;
	f(a->self->i);
}







static void internal_i_e(void* self_) {
	sugar* self = self_;
	(void)self;
	DZN_LOG("sugar.i_e");
	if (self->s == sugar_Enum_False) if (self->s == sugar_Enum_False) {
		args_i_a a = {self};
		args_i_a* p = malloc(sizeof(args_i_a));
		memcpy (p, &a, sizeof(args_i_a));
		runtime_defer(self->rt, self, opaque_i_a, p);
	}
	else {
		int t = sugar_Enum_False;
		if (t == sugar_Enum_True) {
			args_i_a a = {self};
			args_i_a* p = malloc(sizeof(args_i_a));
			memcpy (p, &a, sizeof(args_i_a));
			runtime_defer(self->rt, self, opaque_i_a, p);
		}
	}
}

static void opaque_i_e(void* a) {
	typedef struct {sugar* self;} args;
	args* b = a;
	internal_i_e(b->self);
}

static void i_e(void* self_) {
	sugar* self = ((I*)self_)->in.self;
	typedef struct {sugar* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event((void(*)(void*))opaque_i_e, a);
}


void sugar_init (sugar* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->s = sugar_Enum_False;
	self->i = &self->i_;
	self->i->in.e = i_e;
	self->i->in.self = self;
}
