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

#include "complete.hh"

#include "locator.hh"
#include "runtime.hh"

namespace dezyne
{
  complete::complete(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , p()
  , r()
  {
    p.in.e = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&complete::p_e, this)));
    r.out.a = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&complete::r_a, this)));
  }

  void complete::p_e()
  {
    std::cout << "complete.p_e" << std::endl;
    r.in.e();
  }

  void complete::r_a()
  {
    std::cout << "complete.r_a" << std::endl;
    rt.defer(this, boost::bind(p.out.a));
  }


}
