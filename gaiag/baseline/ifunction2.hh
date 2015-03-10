// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

#ifndef DEZYNE_IFUNCTION2_HH
#define DEZYNE_IFUNCTION2_HH

#include <cassert>
#include <functional>

namespace dezyne
{
  struct ifunction2
  {

    struct
    {
      std::function<void ()> a;
      std::function<void ()> b;

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } in;

    struct
    {
      std::function<void ()> c;
      std::function<void ()> d;

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } out;
  };

  inline void connect (ifunction2& provided, ifunction2& required)
  {
    assert (not required.in.a);
    assert (not required.in.b);

    assert (not provided.out.c);
    assert (not provided.out.d);

    provided.out = required.out;
    required.in = provided.in;
  }

}
#endif // DEZYNE_IFUNCTION2_HH
