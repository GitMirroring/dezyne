// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "component-argument2-c3.hh"

namespace component
{
  argument2::argument2()
  : b(false)
  , i()
  {
    i.in.e = asd::bind(&argument2::e, this);
  }

  void argument2::e()
  {
    std::cout << "argument2.e" << std::endl;
    if (true)
    {
      b = ! (b);
      bool c = g(context, b, b);
      b = g(context, c, c);
      if (c)
      {
        i.out.f();

      }

    }

  }



  bool argument2::g(bool ga, bool gb)
  {
    i.out.f();
    return (ga or gb);

  }




}
