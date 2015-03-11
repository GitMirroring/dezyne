// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "incomplete_with_modeling_event.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  incomplete_with_modeling_event::incomplete_with_modeling_event(const locator& dezyne_locator)
  : meta{"",reinterpret_cast<const component*>(this),0,{},{[this]{p.check_bindings();},[this]{r.check_bindings();}}}
  , rt(dezyne_locator.get<runtime>())
  , p({{"incomplete_with_modeling_event","p",this},{"","",0}})
  , r({{"","",0},{"incomplete_with_modeling_event","r",this}})
  {
    p.in.e = [&] () {
      call_in(this, [this] {p_e();}, std::make_tuple(&p, "e", "return"));
    };
    r.out.a = [&] () {
      call_out(this, [this] {r_a();}, std::make_tuple(&r, "a", "return"));
    };
  }

  void incomplete_with_modeling_event::p_e()
  {
    {
    }
  }

  void incomplete_with_modeling_event::r_a()
  {
    p.out.a();
  }


}
