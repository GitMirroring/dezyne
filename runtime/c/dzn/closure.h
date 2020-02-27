// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef DZN_CLOSURE_H
#define DZN_CLOSURE_H

#include <dzn/config.h>

typedef struct dzn_closure_t dzn_closure;
struct dzn_closure_t{
  void (*func)(void* void_args);
#if DZN_DYNAMIC_QUEUES
  void *args;
#else /* !DZN_DYNAMIC_QUEUES */
  char args[DZN_MAX_ARGS_SIZE];
#endif /* !DZN_DYNAMIC_QUEUES */
};

#endif /* DZN_CLOSURE_H */
