// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "component-modeling-c3.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  modeling::modeling(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , p()
  , r()
  {
    p.in.e = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&modeling::p_e, this)));
    r.out.f = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&modeling::r_f, this)));
  }

  void modeling::p_e()
  {
    std::cout << "modeling.p_e" << std::endl;
    r.in.e();
  }

  void modeling::r_f()
  {
    std::cout << "modeling.r_f" << std::endl;
    {
    }
  }

}
