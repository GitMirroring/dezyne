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

#include "reply_reorder.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  reply_reorder::reply_reorder(const locator& dezyne_locator)
  : dzn_meta{"","reply_reorder",reinterpret_cast<const component*>(this),0,{},{[this]{p.check_bindings();},[this]{r.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , first(true)
  , p({{"p",this},{"",0}})
  , r({{"",0},{"r",this}})
  {
    dzn_rt.performs_flush(this) = true; 
    p.in.start = [&] () {
      call_in(this, [this] {p_start();}, std::make_tuple(&p, "start", "return"));
    };
    r.out.pong = [&] () {
      call_out(this, [this] {r_pong();}, std::make_tuple(&r, "pong", "return"));
    };
  }

  void reply_reorder::p_start()
  {
    {
      r.in.ping();
    }
  }

  void reply_reorder::r_pong()
  {
    if (first)
    {
      p.out.busy();
      first = not (first);
    }
    else if (not (first))
    {
      p.out.finish();
      first = not (first);
    }
  }


}
