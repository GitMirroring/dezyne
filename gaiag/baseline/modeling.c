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

#include "modeling.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>











static void internal_p_e(void* self_) {
	modeling* self = self_;
	(void)self;
	DZN_LOG("modeling.p_e");
	self->r->in.e(self->r);
}

static void internal_r_f(void* self_) {
	modeling* self = self_;
	(void)self;
	DZN_LOG("modeling.r_f");
	{
	}
}

static void opaque_p_e(void* a) {
	typedef struct {modeling* self;} args;
	args* b = a;
	internal_p_e(b->self);
}

static void opaque_r_f(void* a) {
	typedef struct {modeling* self;} args;
	args* b = a;
	internal_r_f(b->self);
}

static void p_e(void* self_) {
	modeling* self = ((dummy*)self_)->in.self;
	typedef struct {modeling* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event((void(*)(void*))opaque_p_e, a);
}

static void r_f(void* self_) {
	modeling* self = ((imodeling*)self_)->out.self;
	typedef struct {modeling* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event((void(*)(void*))opaque_r_f, a);
}


void modeling_init (modeling* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->p = &self->p_;
	self->p->in.e = p_e;
	self->p->in.self = self;
	self->r = &self->r_;
	self->r->out.self = self;
	self->r->out.f = r_f;
}
