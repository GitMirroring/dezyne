// Dezyne --- Dezyne command line tools
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

#include "Comp.hh"

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

namespace dezyne
{
  Comp::Comp(const locator& dezyne_locator)
  : dzn_meta{"","Comp",reinterpret_cast<const component*>(this),0,{},{[this]{client.check_bindings();},[this]{device_A.check_bindings();}}}
  , dzn_rt(dezyne_locator.get<runtime>())
  , s(State::Uninitialized)
  , client({{"client",this},{"",0}})
  , device_A({{"",0},{"device_A",this}})
  {
    dzn_rt.performs_flush(this) = true; 
    client.in.initialize = [&] () {
      return call_in(this, std::function<IComp::result_t::type()>([&] {return client_initialize();}), std::make_tuple(&client, "initialize", "return"));
    };
    client.in.recover = [&] () {
      return call_in(this, std::function<IComp::result_t::type()>([&] {return client_recover();}), std::make_tuple(&client, "recover", "return"));
    };
    client.in.perform_actions = [&] () {
      return call_in(this, std::function<IComp::result_t::type()>([&] {return client_perform_actions();}), std::make_tuple(&client, "perform_actions", "return"));
    };

  }

  IComp::result_t::type Comp::client_initialize()
  {
    if (s == State::Uninitialized)
    {
      {
        IDevice::result_t::type res = device_A.in.initialize ();
        if (res == IDevice::result_t::OK)
        {
          res = device_A.in.calibrate ();
        }
        if (res == IDevice::result_t::OK)
        {
          s = State::Initialized;
          reply_IDevice_result_t = IDevice::result_t::OK;
        }
        else
        {
          s = State::Uninitialized;
          reply_IDevice_result_t = IDevice::result_t::NOK;
        }
      }
    }
    else if (s == State::Initialized)
    {
      assert(false);
    }
    else if (s == State::Error)
    {
      assert(false);
    }
    return reply_IComp_result_t;
  }

  IComp::result_t::type Comp::client_recover()
  {
    if (s == State::Uninitialized)
    {
      assert(false);
    }
    else if (s == State::Initialized)
    {
      assert(false);
    }
    else if (s == State::Error)
    {
      {
        IDevice::result_t::type res = device_A.in.calibrate ();
        if (res == IDevice::result_t::OK)
        {
          s = State::Initialized;
          reply_IDevice_result_t = IDevice::result_t::OK;
        }
        else
        {
          s = State::Error;
          reply_IDevice_result_t = IDevice::result_t::NOK;
        }
      }
    }
    return reply_IComp_result_t;
  }

  IComp::result_t::type Comp::client_perform_actions()
  {
    if (s == State::Uninitialized)
    {
      assert(false);
    }
    else if (s == State::Initialized)
    {
      {
        IDevice::result_t::type res = device_A.in.perform_action1 ();
        if (res == IDevice::result_t::OK)
        {
          res = device_A.in.perform_action2 ();
        }
        if (res == IDevice::result_t::OK)
        {
          s = State::Initialized;
          reply_IDevice_result_t = IDevice::result_t::OK;
        }
        else
        {
          s = State::Error;
          reply_IDevice_result_t = IDevice::result_t::NOK;
        }
      }
    }
    else if (s == State::Error)
    {
      assert(false);
    }
    return reply_IComp_result_t;
  }


  void Comp::check_bindings() const
  {
    dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
  }
  void Comp::dump_tree() const
  {
    dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
  }
}
