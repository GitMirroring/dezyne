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

#include "argument.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  argument::argument(const locator& dezyne_locator)
  : meta{"",reinterpret_cast<const component*>(this),0,{},{[this]{i.check_bindings();}}}
  , rt(dezyne_locator.get<runtime>())
  , b(false)
  , i({{"argument","i",this},{"","",0}})
  {
    i.in.e = [&] () {
      call_in(this, [this] {i_e();}, std::make_tuple(&i, "e", "return"));
    };
  }

  void argument::i_e()
  {
    if (true)
    {
      b = not (b);
      bool c = g (b);
      b = g (c);
      if (c)
      {
        i.out.f();
      }
    }
  }

  bool argument::g(bool gc)
  {
    i.out.f();
    return (gc or b);
  }

}
