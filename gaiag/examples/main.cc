// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

  alarmsystem.po_console.out.detected = detected;
  alarmsystem.po_console.out.deactivated = deactivated;

  alarmsystem.po_console.in.arm();
  alarmsystem.sensor.po_sensor.out.triggered();
  alarmsystem.po_console.in.disarm();
  alarmsystem.sensor.po_sensor.out.disabled();
}
