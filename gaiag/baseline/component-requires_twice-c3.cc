// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Gaiag.
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

#include "component-requires_twice-c3.hh"

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
  requires_twice::requires_twice()
  : p()
  , once()
  , twice()
  {
    p.in.e = connect<void>(this, asd::bind<void>(&requires_twice::p_e, this));
    once.out.a = connect<void>(this, asd::bind<void>(&requires_twice::once_a, this));
    twice.out.a = connect<void>(this, asd::bind<void>(&requires_twice::twice_a, this));
  }

  void requires_twice::p_e()
  {
    std::cout << "requires_twice.p_e" << std::endl;
    {
      once.out.a ();
      twice.out.a ();
    }

  }
  void requires_twice::once_a()
  {
    std::cout << "requires_twice.once_a" << std::endl;

  }
  void requires_twice::twice_a()
  {
    std::cout << "requires_twice.twice_a" << std::endl;

  }



}
