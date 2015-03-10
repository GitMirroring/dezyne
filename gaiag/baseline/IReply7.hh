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

#ifndef DEZYNE_IREPLY7_HH
#define DEZYNE_IREPLY7_HH

#include <cassert>
#include <functional>

namespace dezyne
{
  struct IReply7
  {
    struct E
    {
      enum type
      {
        A
      };
    };

    struct
    {
      std::function<E::type ()> foo;

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } in;

    struct
    {

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } out;
  };

  inline void connect (IReply7& provided, IReply7& required)
  {
    assert (not required.in.foo);


    provided.out = required.out;
    required.in = provided.in;
  }
  inline const char* to_string(IReply7::E::type v)
  {
    switch(v)
    {
      case IReply7::E::A: return "E_A";

    }
    return "";
  }

}
#endif // DEZYNE_IREPLY7_HH
