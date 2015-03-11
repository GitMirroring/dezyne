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

#include "function2.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  function2::function2(const locator& dezyne_locator)
  : meta{"",reinterpret_cast<const component*>(this),0,{},{[this]{i.check_bindings();}}}
  , rt(dezyne_locator.get<runtime>())
  , f(false)
  , i({{"function2","i",this},{"","",0}})
  {
    i.in.a = [&] () {
      call_in(this, [this] {i_a();}, std::make_tuple(&i, "a", "return"));
    };
    i.in.b = [&] () {
      call_in(this, [this] {i_b();}, std::make_tuple(&i, "b", "return"));
    };
  }

  void function2::i_a()
  {
    if (true)
    {
      {
        f = vtoggle ();
      }
    }
  }

  void function2::i_b()
  {
    if (true)
    {
      {
        f = vtoggle ();
        bool bb = vtoggle ();
        f = bb;
        i.out.d();
      }
    }
  }

  bool function2::vtoggle()
  {
    if (f)
    i.out.c();
    return not (f);
  }

}
