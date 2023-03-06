// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2019, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rob Wieringa <rob@dezyne.org>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

/*
 * Generic map manipulation functions
 *
 * Originally by Elliot C Back - http://elliottback.com/wp/map-implementation-in-c/
 *
 * Modified by Pete Warden to fix a serious performance problem, support strings as keys
 * and removed thread synchronization - http://petewarden.typepad.com
 */
#ifndef DZN_MAP_H
#define DZN_MAP_H

#define DZN_MAP_MISSING -3  /* No such element */
#define DZN_MAP_FULL -2     /* Map is full */
#define DZN_MAP_OMEM -1     /* Out of Memory */
#define DZN_MAP_OK 0        /* OK */

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

/* We need to keep keys and values */
typedef struct dzn_map_element dzn_map_element;
struct dzn_map_element
{
  char* key;
  bool in_use;
  void* data;
};

/* A map has some maximum size and current size,
 * as well as the data to hold. */
typedef struct dzn_map dzn_map;
struct dzn_map
{
  size_t table_size;
  size_t size;
  dzn_map_element *data;
};

typedef int32_t (*dzn_map_f)(dzn_map_element* map_el, void* argument);

extern void dzn_map_init (dzn_map* self);

/*
 * Iteratively call f with argument (item, data) for
 * each element data in the map. The function must
 * return a map status code. If it returns anything other
 * than MAP_OK the traversal is terminated. f must
 * not reenter any map functions, or deadlock may arise.
 */
extern int32_t dzn_map_iterate (dzn_map* self, dzn_map_f f, void* item);

/*
 * Add an element to the map. Return MAP_OK or MAP_OMEM.
 */
extern int32_t dzn_map_put (dzn_map* self, char* key, void* value);

/*
 * Get an element from the map. Return MAP_OK or MAP_MISSING.
 */
extern int32_t dzn_map_get (dzn_map const* self, char const* key, void* *arg);

/*
 * Remove an element from the map. Return MAP_OK or MAP_MISSING.
 */
extern int32_t dzn_map_remove (dzn_map* self, char const* key);


/*
 * Free the map
 */
extern void dzn_map_free (dzn_map* self);

/*
 * Get the current size of a map
 */

/* added 4 extra prototypes */
extern uint8_t dzn_map_length (dzn_map const* self);

extern int32_t dzn_map_rehash (dzn_map* self);

extern int32_t dzn_map_hash (dzn_map const* self, char const* key);

extern uint32_t dzn_map_hash_int (dzn_map const* self, char const* keystring);
#endif /* DZN_MAP_H */
