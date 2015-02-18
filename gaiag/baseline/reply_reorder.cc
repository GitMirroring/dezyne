// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
  : rt(dezyne_locator.get<runtime>())
  , first(true)
  , p()
  , r()
  {
    p.in.meta.component = "reply_reorder";
    p.in.meta.port = "p";
    p.in.meta.address = this;
    r.out.meta.component = "reply_reorder";
    r.out.meta.port = "r";
    r.out.meta.address = this;

    p.in.start = connect<void>(rt, this,
    boost::function<void()>
    ([this] ()
    {
      trace (p, "start");
      p_start();
      trace_return (p, "return");
      return;
    }
    ));
    r.out.pong= [this] {trace (r, "pong");
      rt.defer (r.in.meta.address, connect<void>(rt, this,
      boost::function<void()>(
      [this] ()
      {
        r_pong() ;
        return;
      }
      )));};
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
