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

#include "Reply7.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>







static void f(Reply7* self);


static void f(Reply7* self) {
	(void)self;
	int v = self->r->in.foo(self->r);
	self->reply_IReply7_E = v;
}


static int internal_p_foo(void* self_) {
	Reply7* self = self_;
	(void)self;
	DZN_LOG("Reply7.p_foo");
	f (self);
	return self->reply_IReply7_E;
}

static int opaque_p_foo(void* a) {
	typedef struct {Reply7* self;} args;
	args* b = a;
	internal_p_foo(b->self);
	return b->self->reply_IReply7_E;
}

static int p_foo(void* self_) {
	Reply7* self = ((IReply7*)self_)->in.self;
	typedef struct {Reply7* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event((void(*)(void*))opaque_p_foo, a);
	return self->reply_IReply7_E;
}


void Reply7_init (Reply7* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);

	self->p = &self->p_;
	self->p->in.foo = p_foo;
	self->p->in.self = self;
	self->r = &self->r_;
	self->r->out.self = self;
}
