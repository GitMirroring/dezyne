// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include <iostream>

namespace dezyne
{
  middle::middle(const locator& dezyne_locator)
  : dzn_meta{"","middle",reinterpret_cast<const component*>(this),0,{},{[this]{t.check_bindings();},[this]{b.check_bindings();},[this]{l.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , t({{"t",this},{"",0}})
  , b({{"",0},{"b",this}})
  , l(dezyne_locator.get<ilogger>())
  {
    dzn_rt.performs_flush(this) = true; 
    t.in.e = [&] () {
      call_in(this, [this] {t_e();}, std::make_tuple(&t, "e", "return"));
    };
    b.out.f = [&] () {
      call_out(this, [this] {b_f();}, std::make_tuple(&b, "f", "return"));
    };
  }

  void middle::t_e()
  {
    {
      l.in.log();
      b.in.e();
    }
  }

  void middle::b_f()
  {
    {
      l.in.log();
      t.out.f();
    }
  }


}
