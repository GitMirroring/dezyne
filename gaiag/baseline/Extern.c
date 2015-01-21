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

#include "Extern.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>











static void internal_port_e(void* self_) {
	Extern* self = self_;
	(void)self;
	DZN_LOG("Extern.port_e");
	assert(false);
}

static void opaque_port_e(void* a) {
	typedef struct {Extern* self;} args;
	args* b = a;
	internal_port_e(b->self);
}

static void port_e(void* self_) {
	Extern* self = ((IExtern*)self_)->in.self;
	typedef struct {Extern* self;} args;
	args* a = malloc(sizeof(args));
	a->self=self;
	runtime_event((void(*)(void*))opaque_port_e, a);
}


void Extern_init (Extern* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->i = 0;
	;
	self->port = &self->port_;
	self->port->in.e = port_e;
	self->port->in.self = self;
}
