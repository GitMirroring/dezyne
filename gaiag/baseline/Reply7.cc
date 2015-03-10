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

#include "Reply7.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Reply7::Reply7(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , p({{"Reply7","p",this},{0,0,0}})
  , r({{0,0,0},{"Reply7","r",this}})
  {
    p.in.foo = [&] () {
      return call_in(this, std::function<IReply7::E::type()>([&] {return p_foo();}), std::make_tuple(&p, "foo", "return"));
    };
  }

  IReply7::E::type Reply7::p_foo()
  {
    f ();
    return reply_IReply7_E;
  }

  void Reply7::f()
  {
    IReply7::E::type v = r.in.foo ();
    reply_IReply7_E = v;
  }

}
