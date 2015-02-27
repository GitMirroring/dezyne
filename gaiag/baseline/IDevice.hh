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

#ifndef DEZYNE_IDEVICE_HH
#define DEZYNE_IDEVICE_HH

#include <boost/bind.hpp>
#include <boost/function.hpp>

namespace dezyne
{
  struct IDevice
  {
    struct result_t
    {
      enum type
      {
        OK, NOK
      };
    };

    struct
    {
      boost::function<result_t::type ()> initialize;
      boost::function<result_t::type ()> calibrate;
      boost::function<result_t::type ()> perform_action1;
      boost::function<result_t::type ()> perform_action2;

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

  inline void connect (IDevice& provided, IDevice& required)
  {
    assert (not required.in.initialize);
    assert (not required.in.calibrate);
    assert (not required.in.perform_action1);
    assert (not required.in.perform_action2);


    provided.out = required.out;
    required.in = provided.in;
  }
}
#endif // DEZYNE_IDEVICE_HH
