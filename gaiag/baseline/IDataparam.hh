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

#ifndef INTERFACE_IDATAPARAM_C3_HH
#define INTERFACE_IDATAPARAM_C3_HH

#include <boost/bind.hpp>
#include <boost/function.hpp>

namespace dezyne
{
  using boost::function;
  using boost::bind;
}

namespace interface
{
  struct IDataparam
  {
    struct Status
    {
      enum type
      {
        Yes, No
      };
    };

    struct
    {
      dezyne::function<void ()> e0;
      dezyne::function<Status::type ()> e0r;
      dezyne::function<void (int i)> e;
      dezyne::function<Status::type (int i)> er;
      dezyne::function<Status::type (int i, int j)> eer;
      dezyne::function<void (int& i)> eo;
      dezyne::function<void (int& i, int& j)> eoo;
      dezyne::function<void (int i, int& j)> eio;
      dezyne::function<void (int& i)> eio2;
      dezyne::function<Status::type (int& i)> eor;
      dezyne::function<Status::type (int& i, int& j)> eoor;
      dezyne::function<Status::type (int i, int& j)> eior;
      dezyne::function<Status::type (int& i)> eio2r;

    } in;

    struct
    {
      dezyne::function<void ()> a0;
      dezyne::function<void (int i)> a;
      dezyne::function<void (int i, int j)> aa;
      dezyne::function<void (int a0, int a1, int a2, int a3, int a4, int a5)> a6;

    } out;
  };
}

#endif
