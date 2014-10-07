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
  function::function()
  : f(false)
  , po_i() 
  {
    po_i.in.a = connect<void>(this, asd::bind<void>(&function::po_i_a, this));
    po_i.in.b = connect<void>(this, asd::bind<void>(&function::po_i_b, this));
  }

  void function::po_i_a()
  {
    std::cout << "function.po_i_a" << std::endl;
    if (true)

    {
      {
        toggle ();

      }

    }



  }
  void function::po_i_b()
  {
    std::cout << "function.po_i_b" << std::endl;
    if (true)

    {
      {
        toggle ();
        toggle ();
        po_i.out.d ();

      }

    }



  }


  void function::toggle()
  {
    if (f)
    {
      po_i.out.c ();

    }

    f = not (f);


  }

}
