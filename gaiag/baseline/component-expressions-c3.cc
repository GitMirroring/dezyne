// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "component-expressions-c3.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  expressions::expressions(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , state(3)
  , c(0)
  , i()
  {
    i.in.e = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&expressions::i_e, this)));
  }

  void expressions::i_e()
  {
    std::cout << "expressions.i_e" << std::endl;
    if (true)
    {
      if (state == 0)
      {
        state = 3;
        rt.defer(this, dezyne::bind(i.out.a));
      }
      else
      {
        state = state - 1;
        if (c < state)
        {
          c = c + 1;
        }
        else
        if (c <= (state + 1))
        {
          rt.defer(this, dezyne::bind(i.out.lo));
        }
        else
        if (c > state)
        {
          rt.defer(this, dezyne::bind(i.out.hi));
        }
      }
    }
  }

}
