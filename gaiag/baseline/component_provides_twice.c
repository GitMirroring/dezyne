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

#include "component_provides_twice.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>





typedef struct {int size;void (*f)(iprovides_once*);component_provides_twice* self;} args_i_bar;


typedef struct {int size;void (*f)(component_provides_twice*);component_provides_twice* self;} args_i_foo;


static void helper_i_bar(void* args) {
	args_i_bar *a = args;
	a->f(a->self->i);
}



static void helper_i_foo(void* args) {
	args_i_foo *a = args;
	a->f(a->self);
}







static void i_foo(component_provides_twice* self) {
	(void)self;
	assert(false);
}

static void call_in_i_foo(iprovides_once* self) {
	runtime_trace_in(&self->in, &self->out, "foo");
	args_i_foo a = {sizeof(args_i_foo), i_foo, self->in.self};
	runtime_event(helper_i_foo, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void component_provides_twice_init (component_provides_twice* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));

	self->i = &self->i_;
	self->i->in.foo = call_in_i_foo;
	self->i->in.name = "i";
	self->i->in.self = self;
	self->i->out.name = "";
	self->i->out.self = 0;
}
