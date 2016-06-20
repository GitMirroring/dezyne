// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DZN_RUNTIME_H
#define DZN_RUNTIME_H

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include <dzn/queue.h>
#include <dzn/map.h>

typedef struct {
	int dummy;
} runtime;

typedef struct dzn_meta {
  char const* name;
  struct dzn_meta const* parent;
} dzn_meta_t;

typedef struct {
  struct {
    char const* port;
    void* address;
    dzn_meta_t const* meta;
  } provides;
  struct {
    char const* port;
    void* address;
    dzn_meta_t const* meta;
  } requires;
} dzn_port_meta_t;

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
char* runtime_path (dzn_meta_t const* m, char* p);
void runtime_trace_in (dzn_port_meta_t const* m, char const* e);
void runtime_trace_out (dzn_port_meta_t const* m, char const* e);
char* _bool_to_string (bool b);
bool string_to__bool (char *s);
char* _int_to_string (int i);
int string_to__int (char *s);

#define DZN_TRACE(msg) fprintf (stderr, "%s\n", msg)

#endif /* DZN_RUNTIME_H */
