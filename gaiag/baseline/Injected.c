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

#include "Injected.h"

#include <string.h>

#define CONNECT(provided, required)\
{\
	provided->out = required->out;\
	required->in = provided->in;\
}

void Injected_init(Injected *self, locator* dezyne_locator, meta* m) {
	locator* local_locator = locator_clone(dezyne_locator);
	locator_set(local_locator, "ilogger", &self->l.log_);
	memcpy(&self->m, m, sizeof(meta));
	meta m_l = {"l", self};
	logger_init(&self->l, local_locator, &m_l);
	meta m_m = {"m", self};
	middle_init(&self->m, local_locator, &m_m);
	meta m_b = {"b", self};
	bottom_init(&self->b, local_locator, &m_b);
	self->t = self->m.t;
	CONNECT(self->b.b, self->m.b);
}
