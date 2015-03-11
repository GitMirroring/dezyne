// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Choice.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Choice::Choice(const locator& dezyne_locator)
  : meta{"",reinterpret_cast<const component*>(this),0,{},{[this]{c.check_bindings();}}}
  , rt(dezyne_locator.get<runtime>())
  , s(State::Off)
  , c({{"Choice","c",this},{"","",0}})
  {
    c.in.e = [&] () {
      call_in(this, [this] {c_e();}, std::make_tuple(&c, "e", "return"));
    };
  }

  void Choice::c_e()
  {
    if (s == State::Off)
    {
      s = State::Idle;
      c.out.a();
    }
    else if (s == State::Idle)
    {
      s = State::Busy;
      c.out.a();
    }
    else if (s == State::Busy)
    {
      s = State::Idle;
      c.out.a();
    }
  }


}
