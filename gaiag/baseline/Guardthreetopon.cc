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

#include "Guardthreetopon.hh"

#include "locator.hh"
#include "runtime.hh"

namespace dezyne
{
  Guardthreetopon::Guardthreetopon(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , b(false)
  , i()
  , r()
  {
    i.in.e = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Guardthreetopon::i_e, this)));
    i.in.t = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Guardthreetopon::i_t, this)));
    i.in.s = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Guardthreetopon::i_s, this)));
    r.out.a = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Guardthreetopon::r_a, this)));
  }

  void Guardthreetopon::i_e()
  {
    std::cout << "Guardthreetopon.i_e" << std::endl;
    if (true and b)
    {
      rt.defer(this, boost::bind(i.out.a));
    }
    else if (true and not (b))
    {
      bool c = true;
      if (c)
      rt.defer(this, boost::bind(i.out.a));
    }
  }

  void Guardthreetopon::i_t()
  {
    std::cout << "Guardthreetopon.i_t" << std::endl;
    if (b)
    rt.defer(this, boost::bind(i.out.a));
    else if (not (b))
    rt.defer(this, boost::bind(i.out.a));
  }

  void Guardthreetopon::i_s()
  {
    std::cout << "Guardthreetopon.i_s" << std::endl;
    rt.defer(this, boost::bind(i.out.a));
  }

  void Guardthreetopon::r_a()
  {
    std::cout << "Guardthreetopon.r_a" << std::endl;
    {
    }
  }


}
