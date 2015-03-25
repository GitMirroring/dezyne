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

#include "Datasystem.h"

#include <string.h>

#define CONNECT(provided, required)\
{\
	provided->out = required->out;\
	required->in = provided->in;\
}

void Datasystem_init(Datasystem *self, locator* dezyne_locator, meta* m) {
	memcpy(&self->m, m, sizeof(meta));
	meta m_p = {"p", self};
	proxy_init(&self->p, dezyne_locator, &m_p);
	meta m_c = {"c", self};
	Dataparam_init(&self->c, dezyne_locator, &m_c);
	self->port = self->p.top;
	CONNECT(self->c.port, self->p.bottom);
}
