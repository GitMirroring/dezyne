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

#include "Guardthreetopon.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Guardthreetopon::Guardthreetopon(const locator& dezyne_locator)
  : dzn_meta{"","Guardthreetopon",reinterpret_cast<const component*>(this),0,{},{[this]{i.check_bindings();},[this]{r.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , b(false)
  , i({{"i",this},{"",0}})
  , r({{"",0},{"r",this}})
  {
    dzn_rt.performs_flush(this) = true; 
    i.in.e = [&] () {
      call_in(this, [this] {i_e();}, std::make_tuple(&i, "e", "return"));
    };
    i.in.t = [&] () {
      call_in(this, [this] {i_t();}, std::make_tuple(&i, "t", "return"));
    };
    i.in.s = [&] () {
      call_in(this, [this] {i_s();}, std::make_tuple(&i, "s", "return"));
    };
    r.out.a = [&] () {
      call_out(this, [this] {r_a();}, std::make_tuple(&r, "a", "return"));
    };

  }

  void Guardthreetopon::i_e()
  {
    if (true and b)
    {
      i.out.a();
    }
    else if (true and not (b))
    {
      bool c = true;
      if (c)
      i.out.a();
    }
  }

  void Guardthreetopon::i_t()
  {
    if (b)
    i.out.a();
    else if (not (b))
    i.out.a();
  }

  void Guardthreetopon::i_s()
  {
    i.out.a();
  }

  void Guardthreetopon::r_a()
  {
    {
    }
  }


  void Guardthreetopon::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void Guardthreetopon::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
