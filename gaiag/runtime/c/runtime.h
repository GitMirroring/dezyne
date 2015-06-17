// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
#include <stdint.h>
#include <stdio.h>

#include "queue.h"
#include "map.h"

typedef struct {
	int dummy;
} runtime;

typedef struct {
  char const* name;
  void* parent;
} dzn_meta_t;

typedef struct locator locator;
typedef struct runtime_info runtime_info;
struct runtime_info {
  runtime* rt;
  locator* locator;
  bool handling;
  bool performs_flush;
  runtime_info* deferred;
  queue q;
};

typedef struct {
  dzn_meta_t dzn_meta;
  runtime_info dzn_info;
} component;

typedef struct {
  dzn_meta_t dzn_meta;
  runtime_info dzn_info;
  void* self;
} component_header;

void runtime_init (runtime*);
void runtime_illegal_handler();
void runtime_info_init (runtime_info* info, locator* loc);
void runtime_flush (runtime_info* self);
void runtime_defer (void* src, void* tgt, void (*event)(void*), void* args);
void runtime_event (void (*event)(void*), void* args);
char* runtime_path (void* m, char* p);
void runtime_trace_in (void* in, void *out, char const* e);
void runtime_trace_out (void* in, void *out, char const* e);

#define DZN_TRACE(msg) fprintf (stderr, "%s\n", msg)

#endif
