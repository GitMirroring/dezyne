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

#include "locator.h"

#include "runtime.h"
#include <stdlib.h>
#include <string.h>


void locator_init(locator* self, runtime* rt) {
  self->rt = rt;
  self->illegal = runtime_illegal_handler;  
  map_init (&self->services);
}

int map_copy(map_element* elt, void* dst) {
  map* m = dst;
  return map_put (m, elt->key, elt->data);
}

locator* locator_clone(locator* self) {
  locator* clone = malloc(sizeof(locator));
  //memcpy(clone, self, sizeof(locator));
  clone->rt = self->rt;
  map_init (&clone->services);
  map_iterate(&self->services, map_copy, &clone->services); 
  return clone;
}

void* locator_get(locator* self, char* key) {
  void* p = 0;
  map_get (&self->services, key, &p);
  return p;
}

locator* locator_set(locator* self, char* key, void* value) {
  map_put (&self->services, key, value);
  return self;
}
