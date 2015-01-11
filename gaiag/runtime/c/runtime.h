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

#ifndef RUNTIME_H
#define RUNTIME_H

#include <stdbool.h>
#include <stdio.h>

#include "pair.h"
#include "map.h"

typedef struct {
  map map;
} runtime;

void runtime_init (runtime*);

bool* runtime_handling (runtime* self, void* scope);
void runtime_flush (runtime* self, void* scope);
void runtime_defer (runtime* self, void* scope, void *event);
void runtime_handle_event (runtime* self, void* scope, void* event);
void runtime_set (runtime* self, void* scope);
pair* runtime_get (runtime* self, void* scope);

void component_connect_in (void* self, void (**f)(void*), void* event);
void component_connect_out (void* self, void (**f)(void*), void* event);

#define ASD_LOG(msg) printf ("%s\n", msg)

#endif
