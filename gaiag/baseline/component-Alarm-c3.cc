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

void handle_event(void*, const asd::function<void()>&);

template <typename R>
inline asd::function<R()> connect(void*, const asd::function<R()>& event)
{
  return event;
}

template <>
inline asd::function<void()> connect<void>(void* scope, const asd::function<void()>& event)
{
  return asd::bind(handle_event, scope, event);
}

namespace component
{
  Alarm::Alarm()
  : state(States::Disarmed)
  , sounding(false)
  , console()
  , sensor()
  , siren()
  {
    console.in.arm = connect<void>(this, asd::bind<void>(&Alarm::console_arm, this));
    console.in.disarm = connect<void>(this, asd::bind<void>(&Alarm::console_disarm, this));
    sensor.out.triggered = connect<void>(this, asd::bind<void>(&Alarm::sensor_triggered, this));
    sensor.out.disabled = connect<void>(this, asd::bind<void>(&Alarm::sensor_disabled, this));
  }

  void Alarm::console_arm()
  {
    std::cout << "Alarm.console_arm" << std::endl;
    if (state == States::Disarmed)

    {
      {
        sensor.in.enable ();
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
        sensor.in.disable ();
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
        sensor.in.disable ();
        siren.in.turnoff ();
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
        console.out.detected ();
        siren.in.turnon ();
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
          console.out.deactivated ();
          siren.in.turnoff ();
          state = States::Disarmed;
          sounding = false;
        }
        else

        {
          console.out.deactivated ();
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
