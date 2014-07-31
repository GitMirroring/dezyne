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

interface I
{
  in void e;
  out void a;
  out void hi;
  out void lo;
  
  behaviour
  {
    typedef int[0..3] State;

    State state = 3;
    State c = 0;

    [true]
      on e:
      {
        if (state == 0)
        {
          state = 3;
          a;
        }
        else 
        {
          state = state - 1;
          if (c < state)
          {
            c = c + 1;
          }
          else 
            if (c <= (state + 1))
            {
              lo;
            }
            else 
              if (c > state)
              {
                hi;
              }
        }
      }
  }
}

component expressions
{
  provides I i;

  behaviour
  {
    typedef int[0..3] State;

    State state = 3;
    State c = 0;

    [true] 
      on i.e:
      {
        if (state == 0)
        {
          state = 3;
          i.a;
        }
        else 
        {
          state = state - 1;
          if (c < state)
          {
            c = c + 1;
          }
          else 
            if (c <= (state + 1))
            {
              i.lo;
            }
            else
              if (c > state)
              {
                i.hi;
              }
        }
      }
  }
}
