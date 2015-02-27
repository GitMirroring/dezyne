// Dezyne --- Dezyne command line tools
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

#include "GuardedRequiredIllegal.hh"

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

  GuardedRequiredIllegal::GuardedRequiredIllegal(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , c(false)
  , t()
  , b()
  {
    t.in.meta.component = "GuardedRequiredIllegal";
    t.in.meta.port = "t";
    t.in.meta.address = this;
    b.out.meta.component = "GuardedRequiredIllegal";
    b.out.meta.port = "b";
    b.out.meta.address = this;

    t.in.unguarded = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (t, "unguarded");
      t_unguarded();
      trace_return (t, "unguarded");
      return;
    }
    ));
    t.in.e = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (t, "e");
      t_e();
      trace_return (t, "e");
      return;
    }
    ));
    b.out.f = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (b, "f");
      b_f();
      return;
    }
    ));
  }

  void GuardedRequiredIllegal::t_unguarded()
  {
    {
    }
  }

  void GuardedRequiredIllegal::t_e()
  {
    if (not (c))
    {
      c = true;
      b.in.e();
    }
    else if (c)
    {
    }
  }

  void GuardedRequiredIllegal::b_f()
  {
    if (not (c))
    assert(false);
    else if (c)
    {
      c = false;
    }
  }


}
