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

#include "Reply2.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Reply2::Reply2(const locator& dezyne_locator)
  : dzn_meta{"","Reply2",reinterpret_cast<const component*>(this),0,{},{[this]{i.check_bindings();},[this]{u.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , dummy(false)
  , i({{"i",this},{"",0}})
  , u({{"",0},{"u",this}})
  {
    dzn_rt.performs_flush(this) = true; 
    i.in.done = [&] () {
      return call_in(this, std::function<I::Status::type()>([&] {return i_done();}), std::make_tuple(&i, "done", "return"));
    };

  }

  I::Status::type Reply2::i_done()
  {
    if (true)
    {
      U::Status::type s = u.in.what ();
      s = u.in.what ();
      if (s == U::Status::Ok)
      {
        reply_I_Status = I::Status::Yes;
      }
      else
      {
        reply_I_Status = I::Status::No;
      }
    }
    return reply_I_Status;
  }


  void Reply2::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void Reply2::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
