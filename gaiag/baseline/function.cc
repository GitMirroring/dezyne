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

#include "function.hh"

#include "locator.h"
#include "runtime.h"

namespace dezyne
{
  function::function(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , f(false)
  , i()
  {
    i.in.a = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&function::i_a, this)));
    i.in.b = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&function::i_b, this)));
  }

  void function::i_a()
  {
    std::cout << "function.i_a" << std::endl;
    if (true)
    {
      {
        toggle ();
      }
    }
  }

  void function::i_b()
  {
    std::cout << "function.i_b" << std::endl;
    if (true)
    {
      {
        toggle ();
        toggle ();
        rt.defer(this, boost::bind(i.out.d));
      }
    }
  }

  void function::toggle()
  {
    if (f)
    {
      rt.defer(this, boost::bind(i.out.c));
    }
    f = not (f);
  }

}
