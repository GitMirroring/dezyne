// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_ISIREN_HH
#define DEZYNE_ISIREN_HH

#include "meta.hh"

#include <cassert>
#include <functional>

namespace dezyne
{
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

    port::meta meta;
    inline ISiren(port::meta m) : meta(m) {}
  };

  inline void connect (ISiren& provided, ISiren& required)
  {
    assert (not required.in.turnon);
    assert (not required.in.turnoff);


    provided.out = required.out;
    required.in = provided.in;
    provided.meta.requires = required.meta.requires;
    required.meta.provides = provided.meta.provides;
  }

}
#endif // DEZYNE_ISIREN_HH
