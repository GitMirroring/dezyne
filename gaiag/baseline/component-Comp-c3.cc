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

#include "component-Comp-c3.hh"

namespace component
{
  Comp::Comp()
  : s(State::State::Uninitialized)
  , po_client()
  , po_device_A()
  {
    po_client.in.initialize = asd::bind(&Comp::po_client_initialize, this);
    po_client.in.recover = asd::bind(&Comp::po_client_recover, this);
    po_client.in.perform_actions = asd::bind(&Comp::po_client_perform_actions, this);
  }

  interface::IComp::result_t::type Comp::po_client_initialize()
  {
    std::cout << "Comp.po_client_initialize" << std::endl;
    if (s == State::Uninitialized)
    {
      {
        interface::IDevice::result_t::type res = po_device_A.in.initialize();
        if (res == interface::IDevice::result_t::OK)
        {
          res = po_device_A.in.calibrate();

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
      //illegal
    }
    else if (s == State::Error)
    {
      //illegal
    }

    return reply_IComp_result_t;

  }
  interface::IComp::result_t::type Comp::po_client_recover()
  {
    std::cout << "Comp.po_client_recover" << std::endl;
    if (s == State::Uninitialized)
    {
      //illegal
    }
    else if (s == State::Initialized)
    {
      //illegal
    }
    else if (s == State::Error)
    {
      {
        interface::IDevice::result_t::type res = po_device_A.in.calibrate();
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
  interface::IComp::result_t::type Comp::po_client_perform_actions()
  {
    std::cout << "Comp.po_client_perform_actions" << std::endl;
    if (s == State::Uninitialized)
    {
      //illegal
    }
    else if (s == State::Initialized)
    {
      {
        interface::IDevice::result_t::type res = po_device_A.in.perform_action1();
        if (res == interface::IDevice::result_t::OK)
        {
          res = po_device_A.in.perform_action2();

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
      //illegal
    }

    return reply_IComp_result_t;

  }







}
