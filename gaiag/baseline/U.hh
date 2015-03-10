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

#ifndef DEZYNE_U_HH
#define DEZYNE_U_HH

#include <cassert>
#include <functional>

namespace dezyne
{
  struct U
  {
    struct Status
    {
      enum type
      {
        Ok, Nok
      };
    };

    struct
    {
      std::function<Status::type ()> what;

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

  inline void connect (U& provided, U& required)
  {
    assert (not required.in.what);


    provided.out = required.out;
    required.in = provided.in;
  }
  inline const char* to_string(U::Status::type v)
  {
    switch(v)
    {
      case U::Status::Ok: return "Status_Ok";
      case U::Status::Nok: return "Status_Nok";

    }
    return "";
  }

}
#endif // DEZYNE_U_HH
