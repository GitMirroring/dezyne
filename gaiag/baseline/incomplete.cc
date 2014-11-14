// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "incomplete.hh"

#include "locator.hh"
#include "runtime.hh"

namespace dezyne
{
  incomplete::incomplete(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , p()
  , r()
  {
    p.in.e = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&incomplete::p_e, this)));
    r.out.a = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&incomplete::r_a, this)));
  }

  void incomplete::p_e()
  {
    std::cout << "incomplete.p_e" << std::endl;
    {
    }
  }

  void incomplete::r_a()
  {
    std::cout << "incomplete.r_a" << std::endl;
  }


}
