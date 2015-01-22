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

#include "Choice.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
	Choice_State_Off, Choice_State_Idle, Choice_State_Busy
} Choice_State;


typedef struct {Choice* self;} args_c_a;


static void opaque_c_a(void* args) {
	args_c_a *a = args;
	void (*f)(void*) = a->self->c->out.a;
	f(a->self->c);
}







static void internal_c_e(void* self_) {
	Choice* self = self_;
	(void)self;
	DZN_LOG("Choice.c_e");
	if (self->s == Choice_State_Off) {
		self->s = Choice_State_Idle;
		{
			args_c_a a = {self};
			args_c_a* p = malloc(sizeof(args_c_a));
			memcpy (p, &a, sizeof(args_c_a));
			runtime_defer(self->rt, self, opaque_c_a, p);
		}
	}
	else if (self->s == Choice_State_Idle) {
		self->s = Choice_State_Busy;
		{
			args_c_a a = {self};
			args_c_a* p = malloc(sizeof(args_c_a));
			memcpy (p, &a, sizeof(args_c_a));
			runtime_defer(self->rt, self, opaque_c_a, p);
		}
	}
	else if (self->s == Choice_State_Busy) {
		self->s = Choice_State_Idle;
		{
			args_c_a a = {self};
			args_c_a* p = malloc(sizeof(args_c_a));
			memcpy (p, &a, sizeof(args_c_a));
			runtime_defer(self->rt, self, opaque_c_a, p);
		}
	}
}

static void opaque_c_e(void* a) {
	typedef struct {Choice* self;} args;
	args* b = a;
	internal_c_e(b->self);
}

static void c_e(void* self_) {
	Choice* self = ((IChoice*)self_)->in.self;
	typedef struct {Choice* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event((void(*)(void*))opaque_c_e, a);
}


void Choice_init (Choice* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->s = Choice_State_Off;
	self->c = &self->c_;
	self->c->in.e = c_e;
	self->c->in.self = self;
}
