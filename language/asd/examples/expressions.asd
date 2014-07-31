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
  typedef int[0..3] State;

  in void e;
  out void a;
  out void hi;
  out void lo;
  
  behaviour
  {
    State state = 3;
    State i = 0;

    [true]
      on e:
      {
        if (!state)
        {
          state = 3;
          a;
        }
        else 
        {
          state = state - 1;
          if (i < state)
          {
            i = i + 1;
          }
          else if (i <= state)
          {
            lo;
          }
          else if (i > state)
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
    State i = 0;

    [true] 
      on i.e:
      {
        if (!state)
        {
          state = 3;
          i.a;
        }
        else 
        {
          state = state - 1;
          if (i < state)
          {
            i = i + 1;
          }
          else if (i <= state)
          {
            i.lo;
          }
          else if (i > state)
          {
            i.hi;
          }
        }
      }
  }
}
