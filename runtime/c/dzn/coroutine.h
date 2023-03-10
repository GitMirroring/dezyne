// dzn-runtime -- Dezyne runtime library
// Copyright © 2023 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DZN_COROUTINE_H
#define DZN_COROUTINE_H

#include <dzn/config.h>
#if HAVE_LIBPTH
#include <pth.h>
typedef pth_t dzn_coroutine;
#else
typedef int dzn_coroutine;
#endif

typedef struct dzn_interface dzn_interface;
typedef void* (*dzn_coroutine_function) (void*);

int dzn_coroutine_init ();
dzn_coroutine dzn_coroutine_self ();
dzn_coroutine dzn_coroutine_create (dzn_coroutine_function function, void* data);
int dzn_coroutine_yield_to (dzn_coroutine coroutine);

long dzn_coroutine_id ();
int dzn_coroutine_set_id (long id);
dzn_interface* dzn_coroutine_port ();
int dzn_coroutine_set_port (dzn_interface* port);

#endif /* DZN_COROUTINE_H */
