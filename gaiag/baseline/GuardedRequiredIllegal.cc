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

    t.in.unguarded = [&] () {
      call_in(this, std::function<void()>([&] {this->t_unguarded(); }), std::make_tuple(&t, "unguarded", "return"));
    };
    t.in.e = [&] () {
      call_in(this, std::function<void()>([&] {this->t_e(); }), std::make_tuple(&t, "e", "return"));
    };
    b.out.f = [&] () {
      call_out(this, std::function<void()>([&] {this->b_f(); }), std::make_tuple(&b, "f", "return"));
    };
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
