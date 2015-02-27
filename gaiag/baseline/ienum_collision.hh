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

#ifndef DEZYNE_IENUM_COLLISION_HH
#define DEZYNE_IENUM_COLLISION_HH

#include <boost/bind.hpp>
#include <boost/function.hpp>

namespace dezyne
{
  struct ienum_collision
  {
    struct Retval1
    {
      enum type
      {
        OK, NOK
      };
    };
    struct Retval2
    {
      enum type
      {
        OK, NOK
      };
    };

    struct
    {
      boost::function<Retval1::type ()> foo;
      boost::function<Retval2::type ()> bar;

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

  inline void connect (ienum_collision& provided, ienum_collision& required)
  {
    assert (not required.in.foo);
    assert (not required.in.bar);


    provided.out = required.out;
    required.in = provided.in;
  }
}
#endif // DEZYNE_IENUM_COLLISION_HH
