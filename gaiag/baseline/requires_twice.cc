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

#include "requires_twice.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  requires_twice::requires_twice(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , p()
  , once()
  , twice()
  {
    p.in.meta.component = "requires_twice";
    p.in.meta.port = "p";
    p.in.meta.address = this;
    once.out.meta.component = "requires_twice";
    once.out.meta.port = "once";
    once.out.meta.address = this;
    twice.out.meta.component = "requires_twice";
    twice.out.meta.port = "twice";
    twice.out.meta.address = this;

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
    once.out.a= [this] {trace (once, "a");
      rt.defer (once.in.meta.address, connect<void>(rt, this,
      boost::function<void()>(
      [this] ()
      {
        once_a() ;
        return;
      }
      )));};
    twice.out.a= [this] {trace (twice, "a");
      rt.defer (twice.in.meta.address, connect<void>(rt, this,
      boost::function<void()>(
      [this] ()
      {
        twice_a() ;
        return;
      }
      )));};
  }

  void requires_twice::p_e()
  {
    {
      once.in.e();
      twice.in.e();
    }
  }

  void requires_twice::once_a()
  {
    {
    }
  }

  void requires_twice::twice_a()
  {
    {
      p.out.a();
    }
  }


}
