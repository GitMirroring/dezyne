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

#include "testBoolean.h"

#include "locator.h"
#include "runtime.h"
#include <assert.h>





typedef struct {int size;void (*f)(testBoolean*);testBoolean* self;} args_i_evt;




static void helper_i_evt(void* args) {
	args_i_evt *a = args;
	a->f(a->self);
}







static void i_evt(testBoolean* self) {
	(void)self;
	DZN_LOG("testBoolean.i_evt");
	if (true) {
	}
}

static void callback_i_evt(TestBool* self) {
	args_i_evt a = {sizeof(args_i_evt), i_evt, self->in.self};
	runtime_event(helper_i_evt, &a);
}


void testBoolean_init (testBoolean* self, locator* dezyne_locator) {
	self->rt = dezyne_locator->rt;
	runtime_set(self->rt, self);
	self->b = false;
	self->i = &self->i_;
	self->i->in.evt = callback_i_evt;
	self->i->in.self = self;
}
