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

#include "complete.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(icomplete*);complete* self;} args_p_a;


typedef struct {int size;void (*f)(complete*);complete* self;} args_p_e;
typedef struct {int size;void (*f)(complete*);complete* self;} args_r_a;


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







static void p_e(complete* self) {
	(void)self;
	DZN_LOG("complete.p_e");
	self->r->in.e(self->r);
}

static void r_a(complete* self) {
	(void)self;
	DZN_LOG("complete.r_a");
	{
		args_p_a a = {sizeof(args_p_a), self->p->out.a, self};
		runtime_defer(self->rt, self, helper_p_a, &a);
	}
}

static void callback_p_e(icomplete* self) {
	args_p_e a = {sizeof(args_p_e), p_e, self->in.self};
	runtime_event(helper_p_e, &a);
}

static void callback_r_a(icomplete* self) {
	args_r_a a = {sizeof(args_r_a), r_a, self->out.self};
	runtime_event(helper_r_a, &a);
}


void complete_init (complete* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->p = &self->p_;
	self->p->in.e = callback_p_e;
	self->p->in.self = self;
	self->r = &self->r_;
	self->r->out.self = self;
	self->r->out.a = callback_r_a;
}
