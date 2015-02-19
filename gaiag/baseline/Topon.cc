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

#include "Topon.hh"

#include "locator.hh"
#include "runtime.hh"

namespace dezyne
{
  Topon::Topon(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , b(false)
  , c(false)
  , i()
  {
    i.in.e = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Topon::i_e, this)));
    i.in.t = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Topon::i_t, this)));
  }

  void Topon::i_e()
  {
    std::cout << "Topon.i_e" << std::endl;
    if (b and not (c))
    rt.defer(this, boost::bind(i.out.a));
    else if (not (b) and not (c))
    rt.defer(this, boost::bind(i.out.a));
    else if (not (c) and not (b))
    rt.defer(this, boost::bind(i.out.a));
  }

  void Topon::i_t()
  {
    std::cout << "Topon.i_t" << std::endl;
    {
      rt.defer(this, boost::bind(i.out.a));
    }
  }


}
