// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Gaiag.
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

#include "component-function-c3.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  function::function(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , f(false)
  , i()
  {
    i.in.a = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&function::i_a, this)));
    i.in.b = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&function::i_b, this)));
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
        rt.defer(this, dezyne::bind(i.out.d));
      }
    }
  }

  void function::toggle()
  {
    if (f)
    {
      rt.defer(this, dezyne::bind(i.out.c));
    }
    f = not (f);
  }
}
