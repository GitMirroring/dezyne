// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2019, 2023 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DZN_RUNTIME_H
#define DZN_RUNTIME_H

#include <dzn/locator.h>
#include <dzn/meta.h>
#include <dzn/queue.h>

#include <assert.h>
#include <limits.h>
#include <stddef.h>
#if DZN_TRACING
#include <stdio.h>
#endif /* DZN_TRACING */

typedef struct dzn_arguments dzn_arguments;
struct dzn_arguments
{
  size_t size;
  void (*f)(void* argument);
  void* self;
};

typedef struct dzn_runtime_info dzn_runtime_info;
struct dzn_runtime_info
{
  dzn_locator* locator;
  bool handling;
  bool performs_flush;
  dzn_runtime_info* deferred;
  dzn_queue q;
};

typedef struct dzn_component dzn_component;
struct dzn_component
{
#if 1 //DZN_TRACING
  dzn_meta dzn_meta;
#endif /* !DZN_TRACING */
  dzn_runtime_info dzn_info;
};

void dzn_runtime_illegal_handler (void);
void dzn_illegal (dzn_runtime_info const* info);
void dzn_runtime_info_init (dzn_runtime_info* info, dzn_locator* locator);
void dzn_runtime_flush (dzn_runtime_info* info);
void dzn_runtime_defer (void* vsrc, void* vtgt, void (*event)(void*), void* argument);
void dzn_runtime_event (void (*event)(void*), void* argument);
void dzn_runtime_start (dzn_runtime_info* info);
void dzn_runtime_finish (dzn_runtime_info* info);

#if DZN_TRACING
char* dzn_bool_to_string (bool b);
bool dzn_string_to_bool (char *s);
char* dzn_int_to_string (int i);
int dzn_string_to_int (char *s);
char* dzn_runtime_path (dzn_meta const* m, char* p);
void dzn_runtime_trace (dzn_port_meta const* mt, char const* e);
void dzn_runtime_trace_out (dzn_port_meta const* mt, char const* e);
void dzn_runtime_trace_qin (dzn_port_meta const* mt, char const* e);
void dzn_runtime_trace_qout (dzn_port_meta const* mt, char const* e);
#endif /* !DZN_TRACING */

#endif /* DZN_RUNTIME_H */
