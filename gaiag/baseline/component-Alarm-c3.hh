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

#ifndef COMPONENT_ALARM_HH
#define COMPONENT_ALARM_HH

#include "interface-IConsole-c3.hh"
#include "interface-ISensor-c3.hh"
#include "interface-ISiren-c3.hh"


namespace component
{
  struct Alarm
  {
    struct States
    {
      enum type
      {
        Disarmed, Armed, Triggered, Disarming
      };
    };
    Alarm::States::type state;
    bool sounding;
    interface::IConsole console;
    interface::ISensor sensor;
    interface::ISiren siren;

    Alarm();
    void console_arm();
    void console_disarm();
    void sensor_triggered();
    void sensor_disabled();
  };
}
#endif
