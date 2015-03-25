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

#include "incomplete.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>





typedef struct {int size;void (*f)(iincomplete*);incomplete* self;} args_p_a;


typedef struct {int size;void (*f)(incomplete*);incomplete* self;} args_p_e;
typedef struct {int size;void (*f)(incomplete*);incomplete* self;} args_r_a;


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







static void p_e(incomplete* self) {
	(void)self;
	{
	}
}

static void r_a(incomplete* self) {
	(void)self;
	{
	}
}

static void call_in_p_e(iincomplete* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_p_e a = {sizeof(args_p_e), p_e, self->in.self};
	runtime_event(helper_p_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}
static void call_out_r_a(iincomplete* self) {
	runtime_trace_out(&self->in, &self->out, "a");
	args_r_a a = {sizeof(args_r_a), r_a, self->out.self};
	component *c = self->out.self;
	runtime_defer(self->in.self, self->out.self, helper_r_a, &a);
}


void incomplete_init (incomplete* self, locator* dezyne_locator, meta *m) {
	runtime_sub_init(dezyne_locator->rt, &self->sub);
	memcpy(&self->m, m, sizeof(meta));

	self->p = &self->p_;
	self->p->in.e = call_in_p_e;
	self->p->in.name = "p";
	self->p->in.self = self;
	self->r = &self->r_;
	self->r->out.name = "r";
	self->r->out.self = self;
	self->r->out.a = call_out_r_a;
}
