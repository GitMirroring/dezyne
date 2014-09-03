// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

////////////////////////////////////////////////////////////////////////////////

interface TestBool
{
    in void evt;

  behaviour
  {
    enum States { State1, State2 };
    
    bool b1 = true;
    bool b2 = true;
    bool b3 = true;

    States state1 = States.State1;
    States state2 = States.State2;

    [state1.State1]
    {
      on evt:
      {
        // basic boolean operators:
        b1 = b1 || b2;
        b2 = b1 && b2;
        b3 = ! b1;
        b1 = true;
        b2 = false;
        b3 = state1 == States.State2;
        b1 = state2 != States.State2;
        b2 = (b1 && b2);
        b3 = state1.State2;
        // assiciativity:
        b2 = b1 || b2 || b3;
        b3 = b1 && b2 && b3;
        b1 = !!b2;
        // operator precedence:
        b1 = ! b2 && b3;
        b2 = ! b2 || b3;
        b3 = ! (state1 == States.State2);
        b1 = b2 && b3 || b1;
        b2 = b1 || b2 && b3;
        if (state1.State2) {
          b1 = !b1;
        }
      }
    }

    [state2.State1 && b1]
    {
      on evt: {}
    }
  }
}

component testBoolean
{
  provides TestBool i; 
  
  behaviour 
  {
     bool b = false;
     [true] on i.evt: {}
  }
}

