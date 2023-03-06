// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2019, 2013 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rob Wieringa <rob@dezyne.org>
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

#ifndef DZN_LOCATOR_H
#define DZN_LOCATOR_H

#include <dzn/config.h>
#include <dzn/mem.h>

#include <stdbool.h>

#if DZN_LOCATOR_SERVICES
#include <dzn/map.h>
#endif /* !DZN_LOCATOR_SERVICES */

typedef struct dzn_locator dzn_locator;
struct dzn_locator
{
  void (*illegal)(void);
#if DZN_LOCATOR_SERVICES
  dzn_map services;
#endif /* DZN_LOCATOR_SERVICES */
};

void dzn_locator_init (dzn_locator* self);
dzn_locator* dzn_locator_clone (dzn_locator* self);
#if DZN_LOCATOR_SERVICES
int32_t dzn_map_copy (dzn_map_element* elt, void* dst);
void* dzn_locator_get (dzn_locator* self, char* key);
dzn_locator* dzn_locator_set (dzn_locator* self, char* key, void* value);
#endif /* DZN_LOCATOR_SERVICES */

#endif /* DZN_LOCATOR_H */
