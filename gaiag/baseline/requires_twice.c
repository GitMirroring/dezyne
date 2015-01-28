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

#include "requires_twice.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>



typedef struct {int size;void (*f)(void*);requires_twice* self;} args_p_a;


typedef struct {int size;void (*f)(void*);requires_twice* self;} args_p_e;
typedef struct {int size;void (*f)(void*);requires_twice* self;} args_once_a;
typedef struct {int size;void (*f)(void*);requires_twice* self;} args_twice_a;


static void helper_p_a(void* args) {
	args_p_a *a = args;
	a->f(a->self->p);
}



static void helper_p_e(void* args) {
	args_p_e *a = args;
	a->f(a->self);
}

static void helper_once_a(void* args) {
	args_once_a *a = args;
	a->f(a->self);
}

static void helper_twice_a(void* args) {
	args_twice_a *a = args;
	a->f(a->self);
}







static void p_e(void* self_) {
	requires_twice* self = self_;
	(void)self;
	DZN_LOG("requires_twice.p_e");
	self->once->in.e(self->once);
	self->twice->in.e(self->twice);
}

static void once_a(void* self_) {
	requires_twice* self = self_;
	(void)self;
	DZN_LOG("requires_twice.once_a");
	{
	}
}

static void twice_a(void* self_) {
	requires_twice* self = self_;
	(void)self;
	DZN_LOG("requires_twice.twice_a");
	{
		args_p_a a = {sizeof(args_p_a), self->p->out.a, self};
		runtime_defer(self->rt, self, helper_p_a, &a);
	}
}

static void callback_p_e(void* self_) {
	requires_twice* self = ((irequires_twice*)self_)->in.self;
	args_p_e a = {sizeof(args_p_e), p_e, self};
	runtime_event(helper_p_e, &a);
}

static void callback_once_a(void* self_) {
	requires_twice* self = ((irequires_twice*)self_)->out.self;
	args_once_a a = {sizeof(args_once_a), once_a, self};
	runtime_event(helper_once_a, &a);
}

static void callback_twice_a(void* self_) {
	requires_twice* self = ((irequires_twice*)self_)->out.self;
	args_twice_a a = {sizeof(args_twice_a), twice_a, self};
	runtime_event(helper_twice_a, &a);
}


void requires_twice_init (requires_twice* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->p = &self->p_;
	self->p->in.e = callback_p_e;
	self->p->in.self = self;
	self->once = &self->once_;
	self->once->out.self = self;
	self->once->out.a = callback_once_a;
	self->twice = &self->twice_;
	self->twice->out.self = self;
	self->twice->out.a = callback_twice_a;
}
