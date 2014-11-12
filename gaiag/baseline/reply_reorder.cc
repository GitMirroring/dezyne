// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "locator.h"
#include "runtime.h"

namespace component
{
  reply_reorder::reply_reorder(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , first(true)
  , p()
  , r()
  {
    p.in.start = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&reply_reorder::p_start, this)));
    r.out.pong = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&reply_reorder::r_pong, this)));
  }

  void reply_reorder::p_start()
  {
    std::cout << "reply_reorder.p_start" << std::endl;
    {
      r.in.ping();
    }
  }

  void reply_reorder::r_pong()
  {
    std::cout << "reply_reorder.r_pong" << std::endl;
    {
      if (first)
      {
        rt.defer(this, dezyne::bind(p.out.busy));
        first = not (first);
      }
      if (not (first))
      {
        rt.defer(this, dezyne::bind(p.out.finish));
        first = not (first);
      }
    }
  }

}
