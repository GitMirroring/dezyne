// Dezyne --- Dezyne command line tools
//
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

#ifndef ISENSOR_HH
#define ISENSOR_HH

#include "meta.hh"

#include <cassert>
#include <map>




struct ISensor
{

  struct
  {
    std::function<void ()> enable;
    std::function<void ()> disable;
  } in;

  struct
  {
    std::function<void ()> triggered;
    std::function<void ()> disabled;
  } out;

  dezyne::port::meta meta;
  inline ISensor(dezyne::port::meta m) : meta(m) {}

  void check_bindings() const
  {
    if (not in.enable) throw dezyne::binding_error_in(meta, "in.enable");
    if (not in.disable) throw dezyne::binding_error_in(meta, "in.disable");

    if (not out.triggered) throw dezyne::binding_error_out(meta, "out.triggered");
    if (not out.disabled) throw dezyne::binding_error_out(meta, "out.disabled");

  }
};

inline void connect (ISensor& provided, ISensor& required)
{
  provided.out = required.out;
  required.in = provided.in;
  provided.meta.requires = required.meta.requires;
  required.meta.provides = provided.meta.provides;
}





#endif // ISENSOR_HH
