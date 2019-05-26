// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DZN_META_H
#define DZN_META_H

#include <dzn/config.h>


#if DZN_TRACING
typedef struct dzn_meta_t dzn_meta;
struct dzn_meta_t{
  char const* name;
  dzn_meta const* parent;
};
#endif /* DZN_TRACING */


typedef struct dzn_port_meta_t dzn_port_meta;
struct dzn_port_meta_t{
  struct {
    void* address;
#if DZN_TRACING
    char const* port;
    dzn_meta const* meta;
#endif /* DZN_TRACING */
  } provides;
  struct {
    void* address;
#if DZN_TRACING
    char const* port;
    dzn_meta const* meta;
#endif /* DZN_TRACING */
  } requires;
};

#endif /* DZN_META_H */
