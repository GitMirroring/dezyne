// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "expressions.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  expressions::expressions(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , state(3)
  , c(0)
  , i()
  {
    i.in.meta.component = "expressions";
    i.in.meta.port = "i";
    i.in.meta.address = this;

    i.in.e = [&] () {
      call_in(this, std::function<void()>([&] {this->i_e(); }), std::make_tuple(&i, "e", "return"));
    };
  }

  void expressions::i_e()
  {
    if (true)
    {
      if (state == 0)
      {
        state = 3;
        i.out.a();
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
            i.out.lo();
          }
          else
          {
            if (c > state)
            {
              i.out.hi();
            }
          }
        }
      }
    }
  }


}
