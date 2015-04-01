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

#include "Reply7.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>

static char const* IReply7_E_to_string(IReply7_E v)
{
	switch(v)
	{
		case IReply7_E_A: return "E_A";

	}
	return "";
}






typedef struct {int size;int (*f)(Reply7*);Reply7* self;} args_p_foo;




static void helper_p_foo(void* args) {
	args_p_foo *a = args;
	a->f(a->self);
}



static void f(Reply7* self);


static void f(Reply7* self) {
	(void)self;
	int v = self->r->in.foo(self->r);
	self->reply_IReply7_E = v;
}


static int p_foo(Reply7* self) {
	(void)self;
	f (self);
	return self->reply_IReply7_E;
}

static int call_in_p_foo(IReply7* self) {
	runtime_trace_in(&self->in, &self->out, "foo");
	args_p_foo a = {sizeof(args_p_foo), p_foo, self->in.self};
	runtime_event(helper_p_foo, &a);
	Reply7* self_ = self->in.self; 
	runtime_trace_out(&self->in, &self->out, IReply7_E_to_string (self_->reply_IReply7_E));
	return self_->reply_IReply7_E;
}

void Reply7_init (Reply7* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));

	self->p = &self->p_;
	self->p->in.foo = call_in_p_foo;
	self->p->in.name = "p";
	self->p->in.self = self;
	self->p->out.name = "";
	self->p->out.self = 0;
	self->r = &self->r_;
	self->r->in.name = "";
	self->r->in.self = 0;
	self->r->out.name = "r";
	self->r->out.self = self;
}
