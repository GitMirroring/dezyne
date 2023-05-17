// dzn-runtime -- Dezyne runtime library
// Copyright © 2015, 2016, 2019, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2016 Rutger van Beusekom <rutger@dezyne.org>
//
// This file is part of dzn-runtime.
//
// dzn-runtime is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-runtime is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include <dzn/locator.h>
#include <dzn/map.h>
#include <dzn/runtime.h>

#if DZN_LOCATOR_SERVICES
#include <stdlib.h>
#endif /* DZN_LOCATOR_SERVICES */

void
dzn_locator_init (dzn_locator *self)
{
  self->illegal = &dzn_runtime_illegal_handler;
#if DZN_LOCATOR_SERVICES
  dzn_map_init (&self->services);
#endif
}

#if DZN_LOCATOR_SERVICES
int32_t
dzn_map_copy (dzn_map_element *elt, void *dst)
{
  dzn_map *m = dst;
  return dzn_map_put (m, elt->key, elt->data);
}

void *
dzn_locator_get (dzn_locator *self, char *key)
{
  void *p = 0;
  dzn_map_get (&self->services, key, &p);
  return p;
}

dzn_locator *
dzn_locator_set (dzn_locator *self, char *key, void *value)
{
  dzn_map_put (&self->services, key, value);
  return self;
}
#endif /* DZN_LOCATOR_SERVICES */

dzn_locator *
dzn_locator_clone (dzn_locator *self)
{
#if DZN_LOCATOR_SERVICES
  dzn_locator *clone = dzn_malloc (sizeof (dzn_locator));
  dzn_map_init (&clone->services);
  dzn_map_iterate (&self->services, &dzn_map_copy, &clone->services);
  return clone;
#else /* !DZN_LOCATOR_SERVICES */
  return self;
#endif /* !DZN_LOCATOR_SERVICES */
}
