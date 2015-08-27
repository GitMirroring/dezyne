// Dezyne --- Dezyne command line tools
//
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


Alarm::Alarm(const dezyne::locator& dezyne_locator)
: dzn_meta{"","Alarm",reinterpret_cast<const dezyne::component*>(this),0,{},{[this]{console.check_bindings();},[this]{sensor.check_bindings();},[this]{siren.check_bindings();}}}
, dzn_rt(dezyne_locator.get<dezyne::runtime>())
, dzn_locator(dezyne_locator)
, state(States::Disarmed)
, sounding(false)
, console{{{"console",this},{"",0}}}
, sensor{{{"",0},{"sensor",this}}}
, siren{{{"",0},{"siren",this}}}
{
  dzn_rt.performs_flush(this) = true;
  console.in.arm = [&] () {
    dezyne::call_in(this, [this] {console_arm();}, std::make_tuple(&console, "arm", "return"));
  };
  console.in.disarm = [&] () {
    dezyne::call_in(this, [this] {console_disarm();}, std::make_tuple(&console, "disarm", "return"));
  };
  sensor.out.triggered = [&] () {
    dezyne::call_out(this, [this] {sensor_triggered();}, std::make_tuple(&sensor, "triggered", "return"));
  };
  sensor.out.disabled = [&] () {
    dezyne::call_out(this, [this] {sensor_disabled();}, std::make_tuple(&sensor, "disabled", "return"));
  };

}

void Alarm::console_arm()
{
  if (state == States::Disarmed)
  {
    {
      this->sensor.in.enable();
      state = States::Armed;
    }
  }
  else if (state == States::Armed)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
  else if (state == States::Disarming)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
  else if (state == States::Triggered)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
}

void Alarm::console_disarm()
{
  if (state == States::Disarmed)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
  else if (state == States::Armed)
  {
    {
      this->sensor.in.disable();
      state = States::Disarming;
    }

    dzn_rt.handling(this) = false;
    dzn_locator.get<dezyne::pump>().block(&this->console);
  }
  else if (state == States::Disarming)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
  else if (state == States::Triggered)
  {
    {
      this->sensor.in.disable();
      state = States::Disarming;
    }

    dzn_rt.handling(this) = false;
    dzn_locator.get<dezyne::pump>().block(&this->console);
  }
}

void Alarm::sensor_triggered()
{
  if (state == States::Disarmed)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
  else if (state == States::Armed)
  {
    {
      this->console.out.detected();
      this->siren.in.turnon();
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
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
}

void Alarm::sensor_disabled()
{
  if (state == States::Disarmed)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
  else if (state == States::Armed)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
  else if (state == States::Disarming)
  {
    {
      if (sounding)
      {
        this->siren.in.turnoff();
        sounding = false;
      }
      state = States::Disarmed;
      dzn_rt.handling(this) = true;
      dzn_locator.get<dezyne::pump>().release(&this->console);
    }
  }
  else if (state == States::Triggered)
  {
    dzn_locator.get<dezyne::illegal_handler>().illegal();
  }
}


void Alarm::check_bindings() const
{
  dezyne::check_bindings(reinterpret_cast<const dezyne::component*>(this));
}
void Alarm::dump_tree() const
{
  dezyne::dump_tree(reinterpret_cast<const dezyne::component*>(this));
}

