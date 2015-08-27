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

#ifndef ALARM_HH
#define ALARM_HH

#include "IConsole.hh"
#include "ISensor.hh"
#include "ISiren.hh"


#include "runtime.hh"

namespace dezyne {
  struct locator;
  struct runtime;
}


struct Alarm
{
  dezyne::meta dzn_meta;
  dezyne::runtime& dzn_rt;
  dezyne::locator const& dzn_locator;
#ifndef ENUM_Alarm_States
#define ENUM_Alarm_States 1
  struct States
  {
    enum type
    {
      Disarmed, Armed, Triggered, Disarming
    };
  };
#endif // ENUM_Alarm_States
  States::type state;
  bool sounding;
  IConsole console;
  ISensor sensor;
  ISiren siren;

  Alarm(const dezyne::locator&);
  void check_bindings() const;
  void dump_tree() const;

  private:
  void console_arm();
  void console_disarm();
  void sensor_triggered();
  void sensor_disabled();
};

#endif // ALARM_HH
