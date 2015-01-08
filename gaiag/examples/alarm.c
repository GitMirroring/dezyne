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

#include "AlarmSystem.h"

#include "locator.h"
#include "runtime.h"

#define CONNECT(provided, required)\
  {\
  provided.out = required.out; \
  required.in = provided.in; \
  }

static void detected()
{
  ASD_LOG("Console.detected");
}

static void deactivated()
{
  ASD_LOG("Console.deactivated");
}

int main()
{
  dezyne::runtime runtime;
  locator dezyne_locator;
  locator_init(&dezyne_locator);

  AlarmSystem alarmsystem;
  AlarmSystem_init(&alarmsystem, &dezyne_locator);

  CONNECT(alarmsystem.console.out.detected, detected);
  CONNECT(alarmsystem.console.out.deactivated, deactivated);

  alarmsystem.console.in.arm();
  alarmsystem.sensor.sensor.out.triggered();
  alarmsystem.console.in.disarm();
  alarmsystem.sensor.sensor.out.disabled();
}
