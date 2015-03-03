// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "middle.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  middle::middle(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , t()
  , b()
  , l(dezyne_locator.get<ilogger>())
  {
    t.in.meta.component = "middle";
    t.in.meta.port = "t";
    t.in.meta.address = this;
    b.out.meta.component = "middle";
    b.out.meta.port = "b";
    b.out.meta.address = this;
    l.out.meta.component = "middle";
    l.out.meta.port = "l";
    l.out.meta.address = this;

    t.in.e = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (t, "e");
      t_e();
      trace_return (t, "return");
      return;
    }
    ));
    b.out.f=  [this] () {
      trace (b, "f");
      rt.defer (b.in.meta.address, connect<void>(rt, this,
      boost::function<void()>(
      [=]
      {
        b_f();
        return;
      }
      )));};
  }

  void middle::t_e()
  {
    {
      l.in.log();
      b.in.e();
    }
  }

  void middle::b_f()
  {
    {
      l.in.log();
      t.out.f();
    }
  }


}
