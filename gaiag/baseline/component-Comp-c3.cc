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

#include "component-Comp-c3.hh"

#include "locator.h"
#include "runtime.h"

namespace dezyne {
  template <typename R, bool checked>
  inline R valued_helper(runtime& rt, void* scope, const function<R()>& event)
  {
    bool& handle = rt.handling(scope);
    if(checked and handle) throw std::logic_error("a valued event cannot be deferred");

    runtime::scoped_value<bool> sv(handle, true);
    R tmp = event();
    if(not sv.initial)
    {
      rt.flush(scope);
    }
    return tmp;
  }

  template <typename R>
  inline function<R()> connect_in(runtime& rt, void* scope, const function<R()>& event)
  {
    return bind(valued_helper<R,false>, boost::ref(rt), scope, event);
  }

  template <>
  inline function<void()> connect_in<void>(runtime& rt, void* scope, const function<void()>& event)
  {
    return bind(&runtime::handle_event, boost::ref(rt), scope, event);
  }

  template <typename R>
  inline function<R()> connect_out(runtime& rt, void* scope, const function<R()>& event)
  {
    return bind(valued_helper<R,true>, boost::ref(rt), scope, event);
  }

  template <>
  inline function<void()> connect_out<void>(runtime& rt, void* scope, const function<void()>& event)
  {
    return bind(&runtime::handle_event, boost::ref(rt), scope, event);
  }
}

namespace component
{
  Comp::Comp(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , s(State::Uninitialized)
  , client()
  , device_A()
  {
    client.in.initialize = dezyne::connect_in<interface::IComp::result_t::type>(rt, this, dezyne::bind<interface::IComp::result_t::type>(&Comp::client_initialize, this));
    client.in.recover = dezyne::connect_in<interface::IComp::result_t::type>(rt, this, dezyne::bind<interface::IComp::result_t::type>(&Comp::client_recover, this));
    client.in.perform_actions = dezyne::connect_in<interface::IComp::result_t::type>(rt, this, dezyne::bind<interface::IComp::result_t::type>(&Comp::client_perform_actions, this));
  }

  interface::IComp::result_t::type Comp::client_initialize()
  {
    std::cout << "Comp.client_initialize" << std::endl;
    if (s == State::Uninitialized)
    {
      {
        interface::IDevice::result_t::type res = device_A.in.initialize ();
        if (res == interface::IDevice::result_t::OK)
        {
          res = device_A.in.calibrate ();
        }
        if (res == interface::IDevice::result_t::OK)
        {
          s = State::Initialized;
          reply_IDevice_result_t = interface::IDevice::result_t::OK;
        }
        else
        {
          s = State::Uninitialized;
          reply_IDevice_result_t = interface::IDevice::result_t::NOK;
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

  interface::IComp::result_t::type Comp::client_recover()
  {
    std::cout << "Comp.client_recover" << std::endl;
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
        interface::IDevice::result_t::type res = device_A.in.calibrate ();
        if (res == interface::IDevice::result_t::OK)
        {
          s = State::Initialized;
          reply_IDevice_result_t = interface::IDevice::result_t::OK;
        }
        else
        {
          s = State::Error;
          reply_IDevice_result_t = interface::IDevice::result_t::NOK;
        }
      }
    }
    return reply_IComp_result_t;
  }

  interface::IComp::result_t::type Comp::client_perform_actions()
  {
    std::cout << "Comp.client_perform_actions" << std::endl;
    if (s == State::Uninitialized)
    {
      assert(false);
    }
    else if (s == State::Initialized)
    {
      {
        interface::IDevice::result_t::type res = device_A.in.perform_action1 ();
        if (res == interface::IDevice::result_t::OK)
        {
          res = device_A.in.perform_action2 ();
        }
        if (res == interface::IDevice::result_t::OK)
        {
          s = State::Initialized;
          reply_IDevice_result_t = interface::IDevice::result_t::OK;
        }
        else
        {
          s = State::Error;
          reply_IDevice_result_t = interface::IDevice::result_t::NOK;
        }
      }
    }
    else if (s == State::Error)
    {
      assert(false);
    }
    return reply_IComp_result_t;
  }

}
