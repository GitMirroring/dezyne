// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

interface Sensor
{
  in void enable;
  in void disable;

  out void triggered;
  out void disabled;

  behaviour b
  {
    enum States {
        Disabled,
        Enabled,
        Disabling,
        Triggered
    };
    States state = States.Disabled;

    [state.Disabled]
    {
      on enable:
      {
        state = States.Enabled;
      }
      on disable:
        illegal;
    }
    [state.Enabled]
    {
      on enable:
        illegal;
      on disable:
      {
        state = States.Disabling;
      }
      on optional:
      {
        triggered;
        state = States.Triggered;
      }
    }
    [state.Disabling]
    {
      on enable, disable:
        illegal;
      on inevitable:
      {
        disabled;
        state = States.Disabled;
      }
    }
    [state.Triggered]
    {
      on enable:
        illegal;
      on disable:
      {
        state = States.Disabling;
      }
    }
  }
}

component Sensor
{
  provides Sensor sensor;
}
