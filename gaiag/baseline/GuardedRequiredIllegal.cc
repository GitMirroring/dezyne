// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

namespace dezyne
{
  GuardedRequiredIllegal::GuardedRequiredIllegal(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , c(false)
  , t()
  , b()
  {
    t.in.unguarded = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&GuardedRequiredIllegal::t_unguarded, this)));
    t.in.e = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&GuardedRequiredIllegal::t_e, this)));
    b.out.f = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&GuardedRequiredIllegal::b_f, this)));
  }

  void GuardedRequiredIllegal::t_unguarded()
  {
    std::cout << "GuardedRequiredIllegal.t_unguarded" << std::endl;
    {
    }
  }

  void GuardedRequiredIllegal::t_e()
  {
    std::cout << "GuardedRequiredIllegal.t_e" << std::endl;
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
    std::cout << "GuardedRequiredIllegal.b_f" << std::endl;
    if (not (c))
    assert(false);
    else if (c)
    {
      c = false;
    }
  }


}
