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

void handle_event(void*, const asd::function<void()>&);

template <typename R>
inline asd::function<R()> connect(void*, const asd::function<R()>& event)
{
  return event;
}

template <>
inline asd::function<void()> connect<void>(void* scope, const asd::function<void()>& event)
{
  return asd::bind(handle_event, scope, event);
}

namespace component
{
  expressions::expressions()
  : state(3)
  , c(0)
  , po_i()
  {
    po_i.in.e = connect<void>(this, asd::bind<void>(&expressions::po_i_e, this));
  }

  void expressions::po_i_e()
  {
    std::cout << "expressions.po_i_e" << std::endl;
    if (true)

    {
      if (state == 0)
      {
        state = 3;
        po_i.out.a ();

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
          po_i.out.lo ();

        }

        else
        if (c > state)
        {
          po_i.out.hi ();

        }




      }


    }



  }



}
