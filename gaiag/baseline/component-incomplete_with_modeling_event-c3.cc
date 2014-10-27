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

#include "component-incomplete_with_modeling_event-c3.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  incomplete_with_modeling_event::incomplete_with_modeling_event(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , p()
  , r()
  {
    p.in.e = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&incomplete_with_modeling_event::p_e, this)));
    r.out.a = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&incomplete_with_modeling_event::r_a, this)));
  }

  void incomplete_with_modeling_event::p_e()
  {
    std::cout << "incomplete_with_modeling_event.p_e" << std::endl;
  }

  void incomplete_with_modeling_event::r_a()
  {
    std::cout << "incomplete_with_modeling_event.r_a" << std::endl;
    rt.defer(this, dezyne::bind(p.out.a));
  }

}
