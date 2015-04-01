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

#include "provides_twice.h"

#include <string.h>

#define CONNECT(provided, required)\
{\
	provided->out = required->out;\
	required->in = provided->in;\
}

void provides_twice_init(provides_twice *self, locator* dezyne_locator, dzn_meta_t* dzn_meta) {
	memcpy(&self->dzn_meta, dzn_meta, sizeof(dzn_meta_t));
	dzn_meta_t dzn_m_one = {"one", self};
	external_provides_twice_init(&self->one, dezyne_locator, &dzn_m_one);
	self->i = self->one.i;
	self->ii = self->one.ii;
}
