// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DZN_LOCATOR_H
#define DZN_LOCATOR_H

#include <dzn/config.h>
#include <dzn/boolc90.h>
#include <dzn/runloc.h>
#include <dzn/mem.h>

void locator_init(locator* self);
locator* locator_clone(locator* self);
#if DZN_LOCATOR_SERVICES
int32_t map_copy(map_element* elt, void* dst);
void* locator_get(locator* self, char_t* key);
locator* locator_set(locator* self, char_t* key, void* value);
#endif /* DZN_LOCATOR_SERVICES */

#endif /* DZN_LOCATOR_H */
