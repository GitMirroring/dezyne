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

#include "requires_twice.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {requires_twice* self;} args_p_a;


static void opaque_p_a(void* args) {
	args_p_a *a = args;
	void (*f)(void*) = a->self->p->out.a;
	f(a->self->p);
}



static void internal_p_e(void* self_) {
	requires_twice* self = self_;
	(void)self;
	DZN_LOG("requires_twice.p_e");
	self->once->in.e(self->once);
	self->twice->in.e(self->twice);
}

static void internal_once_a(void* self_) {
	requires_twice* self = self_;
	(void)self;
	DZN_LOG("requires_twice.once_a");
	{
	}
}

static void internal_twice_a(void* self_) {
	requires_twice* self = self_;
	(void)self;
	DZN_LOG("requires_twice.twice_a");
	{
		args_p_a a = {self};
		args_p_a* p = malloc(sizeof(args_p_a));
		memcpy (p, &a, sizeof(args_p_a));
		runtime_defer(self->rt, self, opaque_p_a, p);
	}
}

static void opaque_p_e(void* a) {
	typedef struct {requires_twice* self;} args;
	args* b = a;
	internal_p_e(b->self);
}

static void opaque_once_a(void* a) {
	typedef struct {requires_twice* self;} args;
	args* b = a;
	internal_once_a(b->self);
}

static void opaque_twice_a(void* a) {
	typedef struct {requires_twice* self;} args;
	args* b = a;
	internal_twice_a(b->self);
}

static void p_e(void* self_) {
	requires_twice* self = ((irequires_twice*)self_)->in.self;
	typedef struct {requires_twice* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_p_e, a);
}

static void once_a(void* self_) {
	requires_twice* self = ((irequires_twice*)self_)->out.self;
	typedef struct {requires_twice* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_once_a, a);
}

static void twice_a(void* self_) {
	requires_twice* self = ((irequires_twice*)self_)->out.self;
	typedef struct {requires_twice* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_twice_a, a);
}


void requires_twice_init (requires_twice* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->p = &self->p_;
	self->p->in.e = p_e;
	self->p->in.self = self;
	self->once = &self->once_;
	self->once->out.self = self;
	self->once->out.a = once_a;
	self->twice = &self->twice_;
	self->twice->out.self = self;
	self->twice->out.a = twice_a;
}
