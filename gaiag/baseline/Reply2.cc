// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
  template <typename T>
  void trace(const T& t, const char* e)
  {
    std::clog << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << e << " -> " << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << e << std::endl;
  }

  template <typename T>
  void trace_return(const T& t, const char* e)
  {
    std::clog << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << "return" << " -> " << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << "return" << std::endl ;
  }

  Reply2::Reply2(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , dummy(false)
  , i()
  , u()
  {
    i.in.meta.component = "Reply2";
    i.in.meta.port = "i";
    i.in.meta.address = this;
    u.out.meta.component = "Reply2";
    u.out.meta.port = "u";
    u.out.meta.address = this;

    i.in.done = connect<I::Status::type>(rt, this,
    boost::function<I::Status::type()>
    ([this] ()
    {
      trace (i, "done");
      auto r = i_done();
      trace_return (i, "done");
      return r;
    }
    ));
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


}
