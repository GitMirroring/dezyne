// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef DEZYNE_PROVIDES_HH
#define DEZYNE_PROVIDES_HH

#include <boost/bind.hpp>
#include <boost/function.hpp>

namespace dezyne
{
  struct Provides
  {

    struct
    {
      boost::function<void ()> start;

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } in;

    struct
    {
      boost::function<void ()> busy;
      boost::function<void ()> finish;

      struct
      {
        const char* component;
        const char* port;
        void*       address;
      } meta;
    } out;
  };

  inline void connect (Provides& provided, Provides& required)
  {
    assert (not required.in.start);

    assert (not provided.out.busy);
    assert (not provided.out.finish);

    provided.out = required.out;
    required.in = provided.in;
  }
}
#endif // DEZYNE_PROVIDES_HH
