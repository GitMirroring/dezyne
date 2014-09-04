// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
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

