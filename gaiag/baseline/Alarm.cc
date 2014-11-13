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

#include "Alarm.hh"

#include "locator.h"
#include "runtime.h"

namespace dezyne
{
  Alarm::Alarm(const locator& dezyne_locator)
  : rt(dezyne_locator.get<runtime>())
  , state(States::Disarmed)
  , sounding(false)
  , console()
  , sensor()
  , siren()
  {
    console.in.arm = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Alarm::console_arm, this)));
    console.in.disarm = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Alarm::console_disarm, this)));
    sensor.out.triggered = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Alarm::sensor_triggered, this)));
    sensor.out.disabled = connect<void>(rt, this, boost::function<void()>(boost::bind<void>(&Alarm::sensor_disabled, this)));
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
        rt.defer(this, boost::bind(console.out.detected));
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
          rt.defer(this, boost::bind(console.out.deactivated));
          siren.in.turnoff();
          state = States::Disarmed;
          sounding = false;
        }
        else
        {
          rt.defer(this, boost::bind(console.out.deactivated));
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
