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

#include "expressions.hh"

#include "locator.h"
#include "runtime.h"

namespace dezyne
{
  expressions::expressions(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , state(3)
  , c(0)
  , i()
  {
    i.in.e = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&expressions::i_e, this)));
  }

  void expressions::i_e()
  {
    std::cout << "expressions.i_e" << std::endl;
    if (true)
    {
      if (state == 0)
      {
        state = 3;
        rt.defer(this, boost::bind(i.out.a));
      }
      else
      {
        state = state - 1;
        if (c < state)
        {
          c = c + 1;
        }
        else
        {
          if (c <= (state + 1))
          {
            rt.defer(this, boost::bind(i.out.lo));
          }
          else
          {
            if (c > state)
            {
              rt.defer(this, boost::bind(i.out.hi));
            }
          }
        }
      }
    }
  }


}
