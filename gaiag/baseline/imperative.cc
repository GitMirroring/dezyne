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

#include "imperative.hh"

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

  imperative::imperative(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , state(States::I)
  , i()
  {
    i.in.meta.component = "imperative";
    i.in.meta.port = "i";
    i.in.meta.address = this;

    i.in.e = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (i, "e");
      i_e();
      trace_return (i, "e");
      return;
    }
    ));
  }

  void imperative::i_e()
  {
    if (state == States::I)
    {
      rt.defer(this, [=] { i.out.f(); });
      rt.defer(this, [=] { i.out.g(); });
      rt.defer(this, [=] { i.out.h(); });
      state = States::II;
    }
    else if (state == States::II)
    {
      state = States::III;
    }
    else if (state == States::III)
    {
      rt.defer(this, [=] { i.out.f(); });
      rt.defer(this, [=] { i.out.g(); });
      rt.defer(this, [=] { i.out.g(); });
      rt.defer(this, [=] { i.out.f(); });
      state = States::IV;
    }
    else if (state == States::IV)
    {
      rt.defer(this, [=] { i.out.h(); });
      state = States::I;
    }
  }


}
