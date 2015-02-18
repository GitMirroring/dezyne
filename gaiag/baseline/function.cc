// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "function.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  function::function(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , f(false)
  , i()
  {
    i.in.meta.component = "function";
    i.in.meta.port = "i";
    i.in.meta.address = this;

    i.in.a = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (i, "a");
      i_a();
      trace_return (i, "return");
      return;
    }
    ));
    i.in.b = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (i, "b");
      i_b();
      trace_return (i, "return");
      return;
    }
    ));
  }

  void function::i_a()
  {
    if (true)
    {
      {
        toggle ();
      }
    }
  }

  void function::i_b()
  {
    if (true)
    {
      {
        toggle ();
        toggle ();
        i.out.d();
      }
    }
  }

  void function::toggle()
  {
    if (f)
    {
      i.out.c();
    }
    f = not (f);
  }

}
