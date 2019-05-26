// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

#define MAP_MISSING -3  /* No such element */
#define MAP_FULL -2 	/* Map is full */
#define MAP_OMEM -1 	/* Out of Memory */
#define MAP_OK 0 	/* OK */



#include <dzn/boolc90.h>
#include <stddef.h>

/* We need to keep keys and values */
typedef struct map_element_t map_element;
struct map_element_t{
	char_t* key;
	bool in_use;
	void* data;
};

/* A map has some maximum size and current size,
 * as well as the data to hold. */
typedef struct map_t map;
struct map_t{
	size_t table_size;
	size_t size;
	map_element *data;
};

typedef int32_t (*map_f)(map_element* map_el, void* void_args);

extern void map_init(map* self);

/*
 * Iteratively call f with argument (item, data) for
 * each element data in the map. The function must
 * return a map status code. If it returns anything other
 * than MAP_OK the traversal is terminated. f must
 * not reenter any map functions, or deadlock may arise.
 */
extern int32_t map_iterate(map* self, map_f f, void* item);

/*
 * Add an element to the map. Return MAP_OK or MAP_OMEM.
 */
extern int32_t map_put(map* self, char_t* key, void* value);

/*
 * Get an element from the map. Return MAP_OK or MAP_MISSING.
 */
extern int32_t map_get(const map* self, const  char_t* key, void* *arg);

/*
 * Remove an element from the map. Return MAP_OK or MAP_MISSING.
 */
extern int32_t map_remove(map* self, const char_t* key);


/*
 * Free the map
 */
extern void map_free(map* self);

/*
 * Get the current size of a map
 */

/* added 4 extra prototypes */
extern uint8_t map_length(const map* self);

extern int32_t map_rehash(map* self);

extern int32_t map_hash(const map* self, const char_t* key);

extern uint32_t map_hash_int(const map* self, const char_t* keystring);
#endif /* DZN_MAP_H */
