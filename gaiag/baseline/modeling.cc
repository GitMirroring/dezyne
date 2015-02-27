// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "modeling.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  template <typename T>
  void trace(const T& t, const char* e)
  {
    std::clog << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << e << " -> " << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << e << std::endl;
  }

  template <typename T>
  void trace_return(const T& t, const char* e)
  {
    std::clog << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << "return" << " -> " << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << "return" << std::endl ;
  }

  modeling::modeling(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , p()
  , r()
  {
    p.in.meta.component = "modeling";
    p.in.meta.port = "p";
    p.in.meta.address = this;
    r.out.meta.component = "modeling";
    r.out.meta.port = "r";
    r.out.meta.address = this;

    p.in.e = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (p, "e");
      p_e();
      trace_return (p, "e");
      return;
    }
    ));
    r.out.f = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (r, "f");
      r_f();
      return;
    }
    ));
  }

  void modeling::p_e()
  {
    r.in.e();
  }

  void modeling::r_f()
  {
    {
    }
  }


}
