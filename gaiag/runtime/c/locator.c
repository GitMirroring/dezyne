// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include <dzn/runloc.h>
#include <dzn/locator.h>
#include <dzn/map.h>
#include <dzn/runtime.h>


#if DZN_LOCATOR_SERVICES
#include <stdlib.h>
#endif /* DZN_LOCATOR_SERVICES */

void locator_init(locator* self) {
  self->illegal = &runtime_illegal_handler;
#if DZN_LOCATOR_SERVICES
  map_init (&self->services);
#endif
}

#if DZN_LOCATOR_SERVICES
int32_t map_copy(map_element* elt, void* dst) {
  map* m = dst;
  return map_put (m, elt->key, elt->data);
}

void* locator_get(locator* self, char_t* key) {
  void* p = 0;
  map_get (&self->services, key, &p);
  return p;
}

locator* locator_set(locator* self, char_t* key,  void* value) {
  map_put (&self->services, key, value);
  return self;
}
#endif /* DZN_LOCATOR_SERVICES */

locator* locator_clone(locator* self) {
#if DZN_LOCATOR_SERVICES
  locator* clone = dzn_malloc(sizeof(locator));
  map_init (&clone->services);
  map_iterate(&self->services, &map_copy, &clone->services);
  return clone;
#else /* !DZN_LOCATOR_SERVICES */
  return self;
#endif /* !DZN_LOCATOR_SERVICES */
}
