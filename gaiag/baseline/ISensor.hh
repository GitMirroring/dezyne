// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_ISENSOR_HH
#define DEZYNE_ISENSOR_HH

#include <cassert>
#include <functional>

namespace dezyne
{
  struct ISensor
  {

    struct
    {
      std::function<void ()> enable;
      std::function<void ()> disable;

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } in;

    struct
    {
      std::function<void ()> triggered;
      std::function<void ()> disabled;

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } out;
  };

  inline void connect (ISensor& provided, ISensor& required)
  {
    assert (not required.in.enable);
    assert (not required.in.disable);

    assert (not provided.out.triggered);
    assert (not provided.out.disabled);

    provided.out = required.out;
    required.in = provided.in;
  }

}
#endif // DEZYNE_ISENSOR_HH
