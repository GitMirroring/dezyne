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

#include "Reply4.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Reply4::Reply4(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , dummy(false)
  , i({{"Reply4","i",this},{"","",0}})
  , u({{"","",0},{"Reply4","u",this}})
  {
    i.in.done = [&] () {
      return call_in(this, std::function<I::Status::type()>([&] {return i_done();}), std::make_tuple(&i, "done", "return"));
    };
  }

  I::Status::type Reply4::i_done()
  {
    if (true)
    {
      U::Status::type s = u.in.what ();
      s = u.in.what ();
      if (s == U::Status::Ok)
      {
        Reply4::Status::type v = fun ();
        if (v == Status::Yes)
        reply_I_Status = I::Status::Yes;
        else
        reply_I_Status = I::Status::No;
      }
      else
      {
        Reply4::Status::type v = fun_arg (Status::No);
        if (v == Status::Yes)
        reply_I_Status = I::Status::Yes;
        else
        reply_I_Status = I::Status::No;
      }
    }
    return reply_I_Status;
  }

  Reply4::Status::type Reply4::fun()
  {
    return Status::Yes;
  }

  Reply4::Status::type Reply4::fun_arg(Reply4::Status::type s)
  {
    return s;
  }

}
