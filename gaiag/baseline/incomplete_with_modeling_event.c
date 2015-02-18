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

#include "incomplete_with_modeling_event.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(iincomplete_with_modeling_event*);incomplete_with_modeling_event* self;} args_p_a;


typedef struct {int size;void (*f)(incomplete_with_modeling_event*);incomplete_with_modeling_event* self;} args_p_e;
typedef struct {int size;void (*f)(incomplete_with_modeling_event*);incomplete_with_modeling_event* self;} args_r_a;


static void helper_p_a(void* args) {
	args_p_a *a = args;
	a->f(a->self->p);
}



static void helper_p_e(void* args) {
	args_p_e *a = args;
	a->f(a->self);
}

static void helper_r_a(void* args) {
	args_r_a *a = args;
	a->f(a->self);
}







static void p_e(incomplete_with_modeling_event* self) {
	(void)self;
	DZN_LOG("incomplete_with_modeling_event.p_e");
	{
	}
}

static void r_a(incomplete_with_modeling_event* self) {
	(void)self;
	DZN_LOG("incomplete_with_modeling_event.r_a");
	{
		args_p_a a = {sizeof(args_p_a), self->p->out.a, self};
		runtime_defer(&self->sub, helper_p_a, &a);
	}
}

static void callback_p_e(iincomplete_with_modeling_event* self) {
	args_p_e a = {sizeof(args_p_e), p_e, self->in.self};
	runtime_event(helper_p_e, &a);
}

static void callback_r_a(iincomplete_with_modeling_event* self) {
	args_r_a a = {sizeof(args_r_a), r_a, self->out.self};
	runtime_event(helper_r_a, &a);
}


void incomplete_with_modeling_event_init (incomplete_with_modeling_event* self, locator* dezyne_locator) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);

	self->p = &self->p_;
	self->p->in.e = callback_p_e;
	self->p->in.self = self;
	self->r = &self->r_;
	self->r->out.self = self;
	self->r->out.a = callback_r_a;
}
