// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

interface iimperative
{
  in void e;

  out void f;
  out void g;
  out void h;

  behaviour
  {
    enum S {S1, S2};

    //typedef int[0..1] count;

    S s = S.S1;

    bool b = false;
    bool c = true;

    [s.S1]
    {
      on e:
      {
        if(c || b)
        {
          f; g;
        }
        if(b)
        {
          if(c)
          {
            g;
          }
          c = false;
          f;
        }
        else
        {
          if(c)
          {
            b = false;
            h;
          }
          else
          {
            b = true;
            g;
          }
        }
        s = S.S2;
      }
    }
    [s.S2]
    {
      on e:
      {
        if(b)
        {
          if(!c)
          {
            c = true;
          }
          else
          {
            c = false;
          }
          h;
        }
        b = ! b;
        s = S.S1;
      }
    }
  }
}
