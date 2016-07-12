// Dezyne --- Dezyne command line tools
//
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

#ifndef DZN_META_H
#define DZN_META_H

#define DZN_CONNECT(provided, required)               \
{                                                     \
  required->meta.provides = provided->meta.provides;  \
  provided->meta.requires = required->meta.requires;  \
  provided->out = required->out;                      \
  required->in = provided->in;                        \
}

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

#endif
