// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "locator.hh"
#include "runtime.hh"

#include <iostream>

void detected()
{
  std::clog << "Console.detected" << std::endl;
}

void deactivated()
{
  std::clog << "Console.deactivated" << std::endl;
}

int main()
{
  dezyne::runtime runtime;
  dezyne::locator locator;
  AlarmSystem sut(locator.set(runtime));

  sut.dzn_meta.name = "sut";

  sut.console.out.detected = detected;
  sut.console.out.deactivated = deactivated;

  sut.check_bindings();
  sut.dump_tree();

  sut.console.in.arm();
  sut.sensor.sensor.out.triggered();
  runtime.flush(&sut.sensor);
  sut.console.in.disarm();
  sut.sensor.sensor.out.disabled();
  runtime.flush(&sut.sensor);
}
