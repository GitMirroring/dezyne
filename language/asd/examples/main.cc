// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
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

#include "component-AlarmSystem-c3.hh"

void detected()
{
  std::cout << "Console.detected" << std::endl;
}

void deactivated()
{
  std::cout << "Console.deactivated" << std::endl;
}

int main()
{
  component::AlarmSystem alarmsystem;

  alarmsystem.console.out.detected = detected;
  alarmsystem.console.out.deactivated = deactivated;

  alarmsystem.console.in.arm();
  alarmsystem.sensor.sensor.out.triggered();
  alarmsystem.console.in.disarm();
  alarmsystem.sensor.sensor.out.disabled();
}
