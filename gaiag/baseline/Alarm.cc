// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

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
    console.in.meta.component = "Alarm";
    console.in.meta.port = "console";
    console.in.meta.address = this;
    sensor.out.meta.component = "Alarm";
    sensor.out.meta.port = "sensor";
    sensor.out.meta.address = this;
    siren.out.meta.component = "Alarm";
    siren.out.meta.port = "siren";
    siren.out.meta.address = this;

    console.in.arm = [&] () {
      call_in(this, std::function<void()>([&] {this->console_arm(); }), std::make_tuple(&console, "arm", "return"));
    };
    console.in.disarm = [&] () {
      call_in(this, std::function<void()>([&] {this->console_disarm(); }), std::make_tuple(&console, "disarm", "return"));
    };
    sensor.out.triggered = [&] () {
      call_out(this, std::function<void()>([&] {this->sensor_triggered(); }), std::make_tuple(&sensor, "triggered", "return"));
    };
    sensor.out.disabled = [&] () {
      call_out(this, std::function<void()>([&] {this->sensor_disabled(); }), std::make_tuple(&sensor, "disabled", "return"));
    };
  }

  void Alarm::console_arm()
  {
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
    if (state == States::Disarmed)
    {
      assert(false);
    }
    else if (state == States::Armed)
    {
      {
        console.out.detected();
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
    if (state == States::Disarmed)
    {
      assert(false);
    }
    else if (state == States::Armed)
    {
      assert(false);
    }
    else if (state == States::Disarming and sounding)
    {
      console.out.deactivated();
      siren.in.turnoff();
      state = States::Disarmed;
      sounding = false;
    }
    else if (state == States::Disarming and not (sounding))
    {
      console.out.deactivated();
      state = States::Disarmed;
    }
    else if (state == States::Triggered)
    {
      assert(false);
    }
  }


}
