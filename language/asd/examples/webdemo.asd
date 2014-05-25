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

interface Console
{
    in void arm;
    in void disarm;

    out void detected;
    out void deactivated;

  behaviour a
  {
    enum States {
        Disarmed,
        Armed,
        Triggered,
        Disarming
    };

    States state = States.Disarmed;

    [state.Disarmed]
    {
      on arm:
      {
        state = States.Armed;
      }
      on disarm:
        illegal;
    }

    [state.Armed]
    {
      on disarm:
      {
        state = States.Disarming;
      }
      on optional:
      {
        detected;
        state = States.Triggered;
      }
      on arm:
        illegal;
    }

    [state.Triggered]
    {
      on disarm:
      {
        state = States.Disarming;
      }
      on arm:
        illegal;
    }

    [state.Disarming]
    {
      on inevitable:
      {
        deactivated;
        state = States.Disarmed;
      }
      on arm, disarm:
        illegal;
    }
  }
}

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

interface Siren
{
  in void turnon;
  in void turnoff;

  behaviour c
  {
    enum States {
        Off,
        On
    };
    States state = States.Off;

    [state.Off]
    {
      on turnon:
      {
        state = States.On;
      }
      on turnoff:
        illegal;
    }
    [state.On]
    {
      on turnoff:
      {
        state = States.Off;
      }
      on turnon:
        illegal;
    }
  }
}

component Alarm_Impl
{
    provides Console console;
    requires Sensor sensor;
    requires Siren siren;

  behaviour d
  {
    enum States { Disarmed, Armed, Triggered, Disarming };
    States state = States.Disarmed;
    bool sounding = false;

    [state.Disarmed]
    {
      on console.arm:
      {
        sensor.enable;
        state = States.Armed;
      }
      on console.disarm, sensor.triggered, sensor.disabled:
        illegal;
    }
    [state.Armed]
    {
      on console.arm:
        illegal;
      on console.disarm:
      {
        sensor.disable;
        state = States.Disarming;
      }
      on sensor.triggered:
      {
        console.detected;
        siren.turnon;
        sounding = true;
        state = States.Triggered;
      }
      on sensor.disabled:
        illegal;
    }
    [state.Disarming]
    {
      on console.arm, console.disarm:
        illegal;
      on sensor.triggered:
      {
        //illegal;
      }
      on sensor.disabled:
      {
        [sounding]
        {
          console.deactivated;
          state = States.Disarmed;
          sounding = false;
        }
        [otherwise]
        {
          console.deactivated;
          state = States.Disarmed;
        }
      }
    }
    [state.Triggered]
    {
      on console.arm:
        illegal;

      on console.disarm:
      {
        sensor.disable;
        sounding = false;
        state = States.Disarming;
      }
      on sensor.triggered, sensor.disabled:
        illegal;
    }
  }
}
