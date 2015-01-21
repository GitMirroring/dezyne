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

#include "incomplete_with_modeling_event.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>



typedef struct {incomplete_with_modeling_event* self;} args_p_a;


static void opaque_p_a(void* args) {
	args_p_a *a = args;
	void (*f)(void*) = a->self->p->out.a;
	f(a->self->p);
}



static void internal_p_e(void* self_) {
	incomplete_with_modeling_event* self = self_;
	(void)self;
	DZN_LOG("incomplete_with_modeling_event.p_e");
}

static void internal_r_a(void* self_) {
	incomplete_with_modeling_event* self = self_;
	(void)self;
	DZN_LOG("incomplete_with_modeling_event.r_a");
	{
		args_p_a a = {self};
		args_p_a* p = malloc(sizeof(args_p_a));
		memcpy (p, &a, sizeof(args_p_a));
		runtime_defer(self->rt, self, opaque_p_a, p);
	}
}

static void opaque_p_e(void* a) {
	typedef struct {incomplete_with_modeling_event* self;} args;
	args* b = a;
	internal_p_e(b->self);
}

static void opaque_r_a(void* a) {
	typedef struct {incomplete_with_modeling_event* self;} args;
	args* b = a;
	internal_r_a(b->self);
}

static void p_e(void* self_) {
	incomplete_with_modeling_event* self = ((iincomplete_with_modeling_event*)self_)->in.self;
	typedef struct {incomplete_with_modeling_event* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_p_e, a);
}

static void r_a(void* self_) {
	incomplete_with_modeling_event* self = ((iincomplete_with_modeling_event*)self_)->out.self;
	typedef struct {incomplete_with_modeling_event* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event(opaque_r_a, a);
}


void incomplete_with_modeling_event_init (incomplete_with_modeling_event* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->p = &self->p_;
	self->p->in.e = p_e;
	self->p->in.self = self;
	self->r = &self->r_;
	self->r->out.self = self;
	self->r->out.a = r_a;
}
