// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "MachineConstants.hh"

#include <iostream>
#include <stdexcept>

int
config_scope::get(const std::string& key)
{
  static std::map<std::string, int> map;
  if(map.empty())
  {
    map["Position::Robot::Z::Length"] = 149;
    map["Position::Robot::Z::Up"] = -15;
    map["Position::Robot::Z::Down"] = -110;

    map["Position::Robot::Y::Length"] = 629;
    map["Position::Robot::Y::InputPick"] = -70;
    map["Position::Robot::Y::OutputPick"] = -380;
    map["Position::Robot::Y::InputDrop"] = -70;
    map["Position::Robot::Y::RejectPick"] = -380;
    map["Position::Robot::Y::AcceptPick"] = -380;
    map["Position::Robot::Y::RejectDrop"] = -600;
    map["Position::Robot::Y::AcceptDrop"] = -90;

    map["Position::Robot::X::Length"] = 2668;
    map["Position::Robot::X::InputPick"] = 90;
    map["Position::Robot::X::InputDrop"] = 810;
    map["Position::Robot::X::OutputPick"] = 1840;
    map["Position::Robot::X::OutputDrop"] = 2520;

    map["Position::Robot::Gripper::Closed"] = -10;
    map["Position::Robot::Gripper::Open"] = -468;


    map["Position::Inspector::StageXLength"] = 1118;
    map["Position::Inspector::StageYLength"] = 714;

    map["Position::Inspector::ReceiveX"] = 1088;
    map["Position::Inspector::ReceiveY"] = 15;
    map["Position::Inspector::InspectX"] = 1088;
    map["Position::Inspector::InspectY"] = 660;
    map["Position::Inspector::AcceptX"] = 30;
    map["Position::Inspector::AcceptY"] = 357;
    map["Position::Inspector::RejectX"] = 30;
    map["Position::Inspector::RejectY"] = 357;


    map["Position::Feeder::Retracted"] = -150;
    map["Position::Feeder::DropFirst"] = -450;
    map["Position::Feeder::DropSecond"] = -1200;
    map["Position::Feeder::DropThird"] = -1950;
    map["Position::Feeder::DropLast"] = -2700;

    map["Power::15"] = 15;
    map["Power::50"] = 50;

    map["Power::CalibrationSpeed"] = 20;
    map["Power::OperationalSpeed"] = 60;

    map["Power::Gripper::Calibrate"] = 40;
    map["Power::Gripper::Operational"] = 40;


    map["Duration::PollInterval"] = 20;
    map["Duration::Gripper::CalibratePulse"] = 1300;
    map["Duration::Gripper::OperationalPulse"] = 1300;
  }
  if(map.find(key) == map.end())
  {
    throw std::runtime_error("no such key: " + key);
  }
  return map[key];
}

config_scope config;
