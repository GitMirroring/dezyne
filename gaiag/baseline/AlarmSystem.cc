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

#include "AlarmSystem.hh"

namespace dezyne
{
  AlarmSystem::AlarmSystem(const dezyne::locator& dezyne_locator)
  : meta{"",reinterpret_cast<component*>(this),0,{reinterpret_cast<component*>(&alarm),reinterpret_cast<component*>(&sensor),reinterpret_cast<component*>(&siren)}}
  , alarm(dezyne_locator)
  , sensor(dezyne_locator)
  , siren(dezyne_locator)
  , console(alarm.console)
  {
    alarm.meta.parent = reinterpret_cast<component*>(this);
    alarm.meta.address = reinterpret_cast<component*>(&alarm);
    alarm.meta.name = "alarm";
    sensor.meta.parent = reinterpret_cast<component*>(this);
    sensor.meta.address = reinterpret_cast<component*>(&sensor);
    sensor.meta.name = "sensor";
    siren.meta.parent = reinterpret_cast<component*>(this);
    siren.meta.address = reinterpret_cast<component*>(&siren);
    siren.meta.name = "siren";
    connect(sensor.sensor, alarm.sensor);
    connect(siren.siren, alarm.siren);
  }
}
