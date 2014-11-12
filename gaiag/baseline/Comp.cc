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

#include "Comp.hh"

#include "locator.h"
#include "runtime.h"

namespace component
{
  Comp::Comp(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , s(State::Uninitialized)
  , client()
  , device_A()
  {
    client.in.initialize = dezyne::connect<interface::IComp::result_t::type>(rt, this, dezyne::function<interface::IComp::result_t::type()>(dezyne::bind<interface::IComp::result_t::type>(&Comp::client_initialize, this)));
    client.in.recover = dezyne::connect<interface::IComp::result_t::type>(rt, this, dezyne::function<interface::IComp::result_t::type()>(dezyne::bind<interface::IComp::result_t::type>(&Comp::client_recover, this)));
    client.in.perform_actions = dezyne::connect<interface::IComp::result_t::type>(rt, this, dezyne::function<interface::IComp::result_t::type()>(dezyne::bind<interface::IComp::result_t::type>(&Comp::client_perform_actions, this)));
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
