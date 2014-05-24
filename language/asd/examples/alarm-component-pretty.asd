// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Gaiag.
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

component Alarm_Impl
{
  provides Console console;
  requires Sensor sensor;
  requires Siren siren;

  behaviour d
  {
    enum States
    { Disarmed, Armed, Triggered, Disarming };
    States state = States.Disarmed;
    bool sounding = false;
    on console.arm:
    {
      [state.Disarmed]
      {
	sensor.enable;
	state = States.Armed;
      }
      [otherwise]
      {
	illegal;
      }
    }
    on console.disarm:
    {
      [state.Armed || state.Triggered]
      {
	sensor.disable;
	state = States.Disarming;
      }
      [otherwise]
      {
	illegal;
      }
    }
    on sensor.triggered:
    {
      [state.Armed]
      {
	console.detected;
	sounding = true;
	siren.turnon;
	state = States.Triggered;
      }
      [otherwise]
      {
	illegal;
      }
    }
    on sensor.disabled:
    {
      [state.Disarming]
      {
	[sounding]
	{
	  siren.turnoff;
	  sounding = false;
	  console.deactivated;
	  state = States.Disarmed;
	}
	[otherwise]
	{
	  console.deactivated;
	  state = States.Disarmed;
	}
      }
      [otherwise]
      {
	illegal;
      }
    }
  }
}
