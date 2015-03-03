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

#include "complete.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  complete::complete(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , p()
  , r()
  {
    p.in.meta.component = "complete";
    p.in.meta.port = "p";
    p.in.meta.address = this;
    r.out.meta.component = "complete";
    r.out.meta.port = "r";
    r.out.meta.address = this;

    p.in.e = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (p, "e");
      p_e();
      trace_return (p, "return");
      return;
    }
    ));
    r.out.a=  [this] () {
      trace (r, "a");
      rt.defer (r.in.meta.address, connect<void>(rt, this,
      boost::function<void()>(
      [=]
      {
        r_a();
        return;
      }
      )));};
  }

  void complete::p_e()
  {
    {
      r.in.e();
    }
  }

  void complete::r_a()
  {
    {
      p.out.a();
    }
  }


}
