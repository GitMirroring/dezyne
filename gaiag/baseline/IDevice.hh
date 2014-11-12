// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#ifndef INTERFACE_IDEVICE_C3_HH
#define INTERFACE_IDEVICE_C3_HH

#include <boost/bind.hpp>
#include <boost/function.hpp>

namespace dezyne
{
  using boost::function;
  using boost::bind;
}

namespace interface
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
      dezyne::function<result_t::type ()> initialize;
      dezyne::function<result_t::type ()> calibrate;
      dezyne::function<result_t::type ()> perform_action1;
      dezyne::function<result_t::type ()> perform_action2;

    } in;

    struct
    {

    } out;
  };
}

#endif
