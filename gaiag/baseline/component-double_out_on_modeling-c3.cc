// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "component-double_out_on_modeling-c3.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  double_out_on_modeling::double_out_on_modeling(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , state(State::First)
  , p()
  , r()
  {
    p.in.start = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&double_out_on_modeling::p_start, this)));
    r.out.foo = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&double_out_on_modeling::r_foo, this)));
    r.out.bar = dezyne::connect<void>(rt, this, dezyne::function<void()>(dezyne::bind<void>(&double_out_on_modeling::r_bar, this)));
  }

  void double_out_on_modeling::p_start()
  {
    std::cout << "double_out_on_modeling.p_start" << std::endl;
    if (state == State::First)
    {
      {
        r.in.start();
        state = State::Second;
      }
    }
    else if (state == State::Second)
    {
      assert(false);
    }
  }

  void double_out_on_modeling::r_foo()
  {
    std::cout << "double_out_on_modeling.r_foo" << std::endl;
    if (state == State::First)
    {
      assert(false);
    }
    else if (state == State::Second)
    {
      rt.defer(this, dezyne::bind(p.out.foo));
    }
  }

  void double_out_on_modeling::r_bar()
  {
    std::cout << "double_out_on_modeling.r_bar" << std::endl;
    if (state == State::First)
    {
      assert(false);
    }
    else if (state == State::Second)
    {
      {
        rt.defer(this, dezyne::bind(p.out.bar));
        state = State::First;
      }
    }
  }

}
