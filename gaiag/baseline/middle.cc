// Dezyne --- Dezyne command line tools
//
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

#include "middle.hh"

#include "locator.hh"
#include "runtime.hh"

namespace dezyne
{
  middle::middle(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , t()
  , b()
  , l(dezyne_locator.get<ilogger>())
  {
    t.in.e = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&middle::t_e, this)));
    b.out.f = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&middle::b_f, this)));
  }

  void middle::t_e()
  {
    std::cout << "middle.t_e" << std::endl;
    l.in.log();
    b.in.e();
  }

  void middle::b_f()
  {
    std::cout << "middle.b_f" << std::endl;
    l.in.log();
    rt.defer(this, boost::bind(t.out.f));
  }


}
