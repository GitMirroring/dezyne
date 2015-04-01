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

#include "Extern.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <string.h>







typedef struct {int size;void (*f)(Extern*);Extern* self;} args_port_e;




static void helper_port_e(void* args) {
	args_port_e *a = args;
	a->f(a->self);
}







static void port_e(Extern* self) {
	(void)self;
	assert(false);
}

static void call_in_port_e(IExtern* self) {
	runtime_trace_in(&self->in, &self->out, "e");
	args_port_e a = {sizeof(args_port_e), port_e, self->in.self};
	runtime_event(helper_port_e, &a);
	runtime_trace_out(&self->in, &self->out, "return");
}

void Extern_init (Extern* self, locator* dezyne_locator, dzn_meta_t *dzn_meta) {
	runtime_sub_init(dezyne_locator->rt, &self->dzn_sub);
	self->dzn_sub.performs_flush = true;
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	self->i = 0;
	self->port = &self->port_;
	self->port->in.e = call_in_port_e;
	self->port->in.name = "port";
	self->port->in.self = self;
	self->port->out.name = "";
	self->port->out.self = 0;
}
