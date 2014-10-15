// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "component-Alarm-c3.hh"

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
  Alarm::Alarm(const dezyne::locator& dezyne_locator)
  : rt(dezyne_locator.get<dezyne::runtime>())
  , state(States::Disarmed)
  , sounding(false)
  , console()
  , sensor()
  , siren()
  {
    console.in.arm = dezyne::connect_in<void>(rt, this, dezyne::bind<void>(&Alarm::console_arm, this));
    console.in.disarm = dezyne::connect_in<void>(rt, this, dezyne::bind<void>(&Alarm::console_disarm, this));
    sensor.out.triggered = dezyne::connect_out<void>(rt, this, dezyne::bind<void>(&Alarm::sensor_triggered, this));
    sensor.out.disabled = dezyne::connect_out<void>(rt, this, dezyne::bind<void>(&Alarm::sensor_disabled, this));
  }

  void Alarm::console_arm()
  {
    std::cout << "Alarm.console_arm" << std::endl;
    if (state == States::Disarmed)
    {
      {
        sensor.in.enable();
        state = States::Armed;
      }
    }
    else if (state == States::Armed)
    {
      assert(false);
    }
    else if (state == States::Disarming)
    {
      assert(false);
    }
    else if (state == States::Triggered)
    {
      assert(false);
    }
  }

  void Alarm::console_disarm()
  {
    std::cout << "Alarm.console_disarm" << std::endl;
    if (state == States::Disarmed)
    {
      assert(false);
    }
    else if (state == States::Armed)
    {
      {
        sensor.in.disable();
        state = States::Disarming;
      }
    }
    else if (state == States::Disarming)
    {
      assert(false);
    }
    else if (state == States::Triggered)
    {
      {
        sensor.in.disable();
        siren.in.turnoff();
        sounding = false;
        state = States::Disarming;
      }
    }
  }

  void Alarm::sensor_triggered()
  {
    std::cout << "Alarm.sensor_triggered" << std::endl;
    if (state == States::Disarmed)
    {
      assert(false);
    }
    else if (state == States::Armed)
    {
      {
        rt.defer(this, console.out.detected);
        siren.in.turnon();
        sounding = true;
        state = States::Triggered;
      }
    }
    else if (state == States::Disarming)
    {
      {
      }
    }
    else if (state == States::Triggered)
    {
      assert(false);
    }
  }

  void Alarm::sensor_disabled()
  {
    std::cout << "Alarm.sensor_disabled" << std::endl;
    if (state == States::Disarmed)
    {
      assert(false);
    }
    else if (state == States::Armed)
    {
      assert(false);
    }
    else if (state == States::Disarming)
    {
      {
        if (sounding)
        {
          rt.defer(this, console.out.deactivated);
          siren.in.turnoff();
          state = States::Disarmed;
          sounding = false;
        }
        else
        {
          rt.defer(this, console.out.deactivated);
          state = States::Disarmed;
        }
      }
    }
    else if (state == States::Triggered)
    {
      assert(false);
    }
  }

}
