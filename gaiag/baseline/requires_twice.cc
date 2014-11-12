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

#include "requires_twice.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  requires_twice::requires_twice(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , p()
  , once()
  , twice()
  {
    p.in.e = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&requires_twice::p_e, this)));
    once.out.a = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&requires_twice::once_a, this)));
    twice.out.a = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&requires_twice::twice_a, this)));
  }

  void requires_twice::p_e()
  {
    std::cout << "requires_twice.p_e" << std::endl;
    {
      once.in.e();
      twice.in.e();
    }
  }

  void requires_twice::once_a()
  {
    std::cout << "requires_twice.once_a" << std::endl;
    {
    }
  }

  void requires_twice::twice_a()
  {
    std::cout << "requires_twice.twice_a" << std::endl;
    {
      rt.defer(this, dezyne::bind(p.out.a));
    }
  }

}
