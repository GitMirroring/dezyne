// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Adaptor.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Adaptor::Adaptor(const locator& dezyne_locator)
  : dzn_meta{"","Adaptor",reinterpret_cast<const component*>(this),0,{},{[this]{runner.check_bindings();},[this]{console.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , state(State::Idle)
  , count(0)
  , runner({{"runner",this},{"",0}})
  , console({{"",0},{"console",this}})
  {
    dzn_rt.performs_flush(this) = true; 
    runner.in.run = [&] () {
      call_in(this, [this] {runner_run();}, std::make_tuple(&runner, "run", "return"));
    };
    console.out.detected = [&] () {
      call_out(this, [this] {console_detected();}, std::make_tuple(&console, "detected", "return"));
    };
    console.out.deactivated = [&] () {
      call_out(this, [this] {console_deactivated();}, std::make_tuple(&console, "deactivated", "return"));
    };

  }

  void Adaptor::runner_run()
  {
    if (state == State::Idle and count < 2)
    {
      console.in.arm();
      state = State::Active;
    }
    else if (state == State::Idle and not (count < 2))
    {
    }
    else if (state == State::Active)
    {
      {
      }
    }
    else if (state == State::Terminating)
    {
      {
      }
    }
  }

  void Adaptor::console_detected()
  {
    if (state == State::Idle)
    {
      assert(false);
    }
    else if (state == State::Active)
    {
      {
        count = count + 1;
        console.in.disarm();
        state = State::Terminating;
      }
    }
    else if (state == State::Terminating)
    {
      assert(false);
    }
  }

  void Adaptor::console_deactivated()
  {
    if (state == State::Idle)
    {
      assert(false);
    }
    else if (state == State::Active)
    {
      assert(false);
    }
    else if (state == State::Terminating and count < 2)
    {
      console.in.arm();
      state = State::Active;
    }
    else if (state == State::Terminating and not (count < 2))
    state = State::Idle;
  }


  void Adaptor::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void Adaptor::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
