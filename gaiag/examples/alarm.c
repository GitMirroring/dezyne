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

static void detected()
{
  DZN_TRACE("Console.detected");
}

static void deactivated()
{
  DZN_TRACE("Console.deactivated");
}

int main()
{
  runtime dezyne_runtime;
  runtime_init (&dezyne_runtime);

  locator dezyne_locator;
  locator_init (&dezyne_locator, &dezyne_runtime);

  AlarmSystem alarmsystem;
  meta m = {"alarmsystem", 0};
  AlarmSystem_init(&alarmsystem, &dezyne_locator, &m);
  alarmsystem.console->out.name = "console";
  alarmsystem.console->out.self = &alarmsystem;

  alarmsystem.console->out.detected = detected;

  alarmsystem.console->out.deactivated = deactivated;

  alarmsystem.console->in.arm(alarmsystem.console);
  alarmsystem.sensor.sensor->out.triggered(alarmsystem.sensor.sensor);
  alarmsystem.console->in.disarm(alarmsystem.console);
  alarmsystem.sensor.sensor->out.disabled(alarmsystem.sensor.sensor);
  return 0;
}
