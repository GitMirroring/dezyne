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

#include "Topon.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Topon::Topon(const locator& dezyne_locator)
  : dzn_meta{"","Topon",reinterpret_cast<const component*>(this),0,{},{[this]{i.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , b(false)
  , c(false)
  , i({{"i",this},{"",0}})
  {
    dzn_rt.performs_flush(this) = true; 
    i.in.e = [&] () {
      call_in(this, [this] {i_e();}, std::make_tuple(&i, "e", "return"));
    };
    i.in.t = [&] () {
      call_in(this, [this] {i_t();}, std::make_tuple(&i, "t", "return"));
    };

  }

  void Topon::i_e()
  {
    if (b and not (c))
    i.out.a();
    else if (not (b) and not (c))
    i.out.a();
    else if (not (c) and not (b))
    i.out.a();
  }

  void Topon::i_t()
  {
    {
      i.out.a();
    }
  }


  void Topon::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void Topon::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
