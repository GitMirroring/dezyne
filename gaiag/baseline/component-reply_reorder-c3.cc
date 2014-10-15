// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "component-reply_reorder-c3.hh"

void handle_event(void*, const asd::function<void()>&);

template <typename R>
inline asd::function<R()> connect(void*, const asd::function<R()>& event)
{
  return event;
}

template <>
inline asd::function<void()> connect<void>(void* scope, const asd::function<void()>& event)
{
  return asd::bind(handle_event, scope, event);
}

namespace component
{
  reply_reorder::reply_reorder()
  : first(true)
  , p()
  , r()
  {
    p.in.start = connect<void>(this, asd::bind<void>(&reply_reorder::p_start, this));
    r.out.pong = connect<void>(this, asd::bind<void>(&reply_reorder::r_pong, this));
  }

  void reply_reorder::p_start()
  {
    std::cout << "reply_reorder.p_start" << std::endl;
    {
      r.in.ping ();
    }
  }

  void reply_reorder::r_pong()
  {
    std::cout << "reply_reorder.r_pong" << std::endl;
    {
      if (first)
      {
        p.out.busy ();
        first = not (first);
      }
      if (not (first))
      {
        p.out.finish ();
        first = not (first);
      }
    }
  }

}
