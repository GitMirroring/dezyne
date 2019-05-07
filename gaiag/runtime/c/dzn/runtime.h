// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DZN_RUNTIME_H
#define DZN_RUNTIME_H

#include <assert.h>
#include <limits.h>

#include <dzn/queue.h>
#include <dzn/runloc.h>
#include <dzn/meta.h>
#include <stddef.h>
#if DZN_TRACING
#include <stdio.h>
#endif /* DZN_TRACING */


typedef struct arguments_t arguments;
struct arguments_t{
  size_t size;
  void (*f)(void* void_args);
  void* self;
};


typedef struct component_t component;
struct component_t{
#if DZN_TRACING
  dzn_meta meta;
#endif /* !DZN_TRACING */
  runtime_info dzn_info;
};

void runtime_illegal_handler(void);
void dzn_illegal(const runtime_info* info);
void runtime_info_init (runtime_info* info, locator* loc);
void runtime_flush (runtime_info* info);
void runtime_defer (void* vsrc, void* vtgt, void (*event)(void* void_args), void* args);
void runtime_event (void (*event)(void* void_args), void* args);
void runtime_start (runtime_info* info);
void runtime_finish (runtime_info* info);


#if DZN_TRACING

char* _bool_to_string (bool b);
bool string_to__bool (char *s);
char* _int_to_string (int i);
int string_to__int (char *s);
char* runtime_path (dzn_meta const* m, char* p);
void runtime_trace (dzn_port_meta const* mt, char const* e);
void runtime_trace_out (dzn_port_meta const* mt, char const* e);
void runtime_trace_qin (dzn_port_meta const* mt, char const* e);
void runtime_trace_qout (dzn_port_meta const* mt, char const* e);
#endif /* !DZN_TRACING */

#endif /* DZN_RUNTIME_H */
