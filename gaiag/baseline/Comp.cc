// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
  template <typename T>
  void trace(const T& t, const char* e)
  {
    std::clog << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << e << " -> " << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << e << std::endl;
  }

  template <typename T>
  void trace_return(const T& t, const char* e)
  {
    std::clog << t.in.meta.address << ":" << t.in.meta.component << "." << t.in.meta.port << "." << "return" << " -> " << t.out.meta.address << ":" << t.out.meta.component << "." << t.out.meta.port << "." << "return" << std::endl ;
  }

  Comp::Comp(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , s(State::Uninitialized)
  , client()
  , device_A()
  {
    client.in.meta.component = "Comp";
    client.in.meta.port = "client";
    client.in.meta.address = this;
    device_A.out.meta.component = "Comp";
    device_A.out.meta.port = "device_A";
    device_A.out.meta.address = this;

    client.in.initialize = connect<IComp::result_t::type>(rt, this,
    boost::function<IComp::result_t::type()>
    ([this] ()
    {
      trace (client, "initialize");
      auto r = client_initialize();
      trace_return (client, "initialize");
      return r;
    }
    ));
    client.in.recover = connect<IComp::result_t::type>(rt, this,
    boost::function<IComp::result_t::type()>
    ([this] ()
    {
      trace (client, "recover");
      auto r = client_recover();
      trace_return (client, "recover");
      return r;
    }
    ));
    client.in.perform_actions = connect<IComp::result_t::type>(rt, this,
    boost::function<IComp::result_t::type()>
    ([this] ()
    {
      trace (client, "perform_actions");
      auto r = client_perform_actions();
      trace_return (client, "perform_actions");
      return r;
    }
    ));
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


}
