// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef RUNLOC_H
#define RUNLOC_H

#include <dzn/boolc90.h>
#include <dzn/config.h>
#include <dzn/queue.h>

#if DZN_LOCATOR_SERVICES
#include <dzn/map.h>
#endif /* !DZN_LOCATOR_SERVICES */


typedef struct locator_t locator;
struct locator_t {
	void (*illegal)(void);

#if DZN_LOCATOR_SERVICES
  map services;
#endif /* DZN_LOCATOR_SERVICES */
};

typedef struct runtime_info_t runtime_info;
struct runtime_info_t{
  locator* lc;
  bool handling;
  bool performs_flush;
  runtime_info* deferred;
  queue q;
};

#endif /* RUNLOC_H */
