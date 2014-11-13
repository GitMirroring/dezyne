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

#ifndef DEZYNE_IDATAPARAM_HH
#define DEZYNE_IDATAPARAM_HH

#include <boost/bind.hpp>
#include <boost/function.hpp>

namespace dezyne
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
      boost::function<void ()> e0;
      boost::function<Status::type ()> e0r;
      boost::function<void (int i)> e;
      boost::function<Status::type (int i)> er;
      boost::function<Status::type (int i, int j)> eer;
      boost::function<void (int& i)> eo;
      boost::function<void (int& i, int& j)> eoo;
      boost::function<void (int i, int& j)> eio;
      boost::function<void (int& i)> eio2;
      boost::function<Status::type (int& i)> eor;
      boost::function<Status::type (int& i, int& j)> eoor;
      boost::function<Status::type (int i, int& j)> eior;
      boost::function<Status::type (int& i)> eio2r;

    } in;

    struct
    {
      boost::function<void ()> a0;
      boost::function<void (int i)> a;
      boost::function<void (int i, int j)> aa;
      boost::function<void (int a0, int a1, int a2, int a3, int a4, int a5)> a6;

    } out;
  };
}
#endif // DEZYNE_IDATAPARAM_HH
