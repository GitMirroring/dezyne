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

#ifndef ISIREN_HH
#define ISIREN_HH

#include "meta.hh"

#include <cassert>
#include <map>




struct ISiren
{

  struct
  {
    std::function<void ()> turnon;
    std::function<void ()> turnoff;
  } in;

  struct
  {
  } out;

  dezyne::port::meta meta;
  inline ISiren(dezyne::port::meta m) : meta(m) {}

  void check_bindings() const
  {
    if (not in.turnon) throw dezyne::binding_error_in(meta, "in.turnon");
    if (not in.turnoff) throw dezyne::binding_error_in(meta, "in.turnoff");


  }
};

inline void connect (ISiren& provided, ISiren& required)
{
  provided.out = required.out;
  required.in = provided.in;
  provided.meta.requires = required.meta.requires;
  required.meta.provides = provided.meta.provides;
}





#endif // ISIREN_HH
