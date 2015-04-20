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

#ifndef LOCATOR_H
#define LOCATOR_H

#include "runtime.h"

typedef struct locator locator;
struct locator {
	runtime* rt;
	void (*illegal)();
  	map services;

};

void locator_init(locator* self, runtime* rt);
locator* locator_clone(locator* self);
void* locator_get(locator* self, char* key);
locator* locator_set(locator* self, char* key, void* value);

#endif // LOCATOR_H
