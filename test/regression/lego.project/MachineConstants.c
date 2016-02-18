// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "MachineConstants.h"

#include <stdio.h>
#include <dzn/map.h>
#include <dzn/mem.h>

static char*
map_key (void* scope)
{
  static char buf[sizeof (void*) * 2 + 3];
  sprintf (buf, "%p", scope);
  return buf;
}

int
map_put_int (map* self, char* key, int i)
{
  int *p = malloc (sizeof(int));
  *p = i;
  return map_put (self, key, p);
}

int
map_get_int (map* self, char* key, int **p)
{
  return map_get (self, key, (void**)p);
}

int
config_get (char* key)
{
  static map* m = 0;
  if (!m)
  {
    m = (map*)dzn_malloc (sizeof (map));
    map_init (m);

    map_put_int (m, "Position::Robot::Z::Length", 149);
    map_put_int (m, "Position::Robot::Z::Up", -15);
    map_put_int (m, "Position::Robot::Z::Down", -110);

    map_put_int (m, "Position::Robot::Y::Length", 629);
    map_put_int (m, "Position::Robot::Y::InputPick", -70);
    map_put_int (m, "Position::Robot::Y::OutputPick", -380);
    map_put_int (m, "Position::Robot::Y::InputDrop", -70);
    map_put_int (m, "Position::Robot::Y::RejectPick", -380);
    map_put_int (m, "Position::Robot::Y::AcceptPick", -380);
    map_put_int (m, "Position::Robot::Y::RejectDrop", -600);
    map_put_int (m, "Position::Robot::Y::AcceptDrop", -90);

    map_put_int (m, "Position::Robot::X::Length", 2668);
    map_put_int (m, "Position::Robot::X::InputPick", 90);
    map_put_int (m, "Position::Robot::X::InputDrop", 810);
    map_put_int (m, "Position::Robot::X::OutputPick", 1840);
    map_put_int (m, "Position::Robot::X::OutputDrop", 2520);

    map_put_int (m, "Position::Robot::Gripper::Closed", -10);
    map_put_int (m, "Position::Robot::Gripper::Open", -468);


    map_put_int (m, "Position::Inspector::StageXLength", 1118);
    map_put_int (m, "Position::Inspector::StageYLength", 714);

    map_put_int (m, "Position::Inspector::ReceiveX", 1088);
    map_put_int (m, "Position::Inspector::ReceiveY", 15);
    map_put_int (m, "Position::Inspector::InspectX", 1088);
    map_put_int (m, "Position::Inspector::InspectY", 660);
    map_put_int (m, "Position::Inspector::AcceptX", 30);
    map_put_int (m, "Position::Inspector::AcceptY", 357);
    map_put_int (m, "Position::Inspector::RejectX", 30);
    map_put_int (m, "Position::Inspector::RejectY", 357);


    map_put_int (m, "Position::Feeder::Retracted", -150);
    map_put_int (m, "Position::Feeder::DropFirst", -450);
    map_put_int (m, "Position::Feeder::DropSecond", -1200);
    map_put_int (m, "Position::Feeder::DropThird", -1950);
    map_put_int (m, "Position::Feeder::DropLast", -2700);


    map_put_int (m, "Power::15", 15);
    map_put_int (m, "Power::50", 50);

    map_put_int (m, "Power::CalibrationSpeed", 20);
    map_put_int (m, "Power::OperationalSpeed", 60);

    map_put_int (m, "Power::Gripper::Calibrate", 40);
    map_put_int (m, "Power::Gripper::Operational", 40);


    map_put_int (m, "Duration::PollInterval", 20);
    map_put_int (m, "Duration::Gripper::CalibratePulse", 1300);
    map_put_int (m, "Duration::Gripper::OperationalPulse", 1300);
  }
  int* i;
  map_get_int (m, key, &i);
  return *i;
}

config_scope config = {config_get};
