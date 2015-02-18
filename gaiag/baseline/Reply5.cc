// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Reply5.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Reply5::Reply5(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , dummy(false)
  , i()
  , u()
  {
    i.in.meta.component = "Reply5";
    i.in.meta.port = "i";
    i.in.meta.address = this;
    u.out.meta.component = "Reply5";
    u.out.meta.port = "u";
    u.out.meta.address = this;

    i.in.done = connect<I::Status::type>(rt, this,
    boost::function<I::Status::type()>
    ([this] ()
    {
      trace (i, "done");
      auto r = i_done();
      trace_return (i, I::Status::to_string(r));
      return r;
    }
    ));
  }

  I::Status::type Reply5::i_done()
  {
    if (true)
    {
      U::Status::type s = u.in.what ();
      s = u.in.what ();
      if (s == U::Status::Ok)
      {
        I::Status::type s = fun ();
        reply_I_Status = s;
      }
      else
      {
        I::Status::type s = fun_arg (I::Status::No);
        reply_I_Status = s;
      }
    }
    return reply_I_Status;
  }

  I::Status::type Reply5::fun()
  {
    return I::Status::Yes;
  }

  I::Status::type Reply5::fun_arg(I::Status::type s)
  {
    return s;
  }

}
