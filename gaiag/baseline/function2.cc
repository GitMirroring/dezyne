// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "function2.hh"

#include "locator.hh"
#include "runtime.hh"

namespace dezyne
{
  function2::function2(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , f(false)
  , i()
  {
    i.in.a = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&function2::i_a, this)));
    i.in.b = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&function2::i_b, this)));
  }

  void function2::i_a()
  {
    std::cout << "function2.i_a" << std::endl;
    if (true)
    {
      {
        f = vtoggle ();
      }
    }
  }

  void function2::i_b()
  {
    std::cout << "function2.i_b" << std::endl;
    if (true)
    {
      {
        f = vtoggle ();
        bool bb = vtoggle ();
        f = bb;
        rt.defer(this, boost::bind(i.out.d));
      }
    }
  }

  bool function2::vtoggle()
  {
    if (f)
    rt.defer(this, boost::bind(i.out.c));
    return not (f);
  }

}
