// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  enum Status { Yes, No };

  in void e;
  out void a;
  out void hi;
  out void lo;

  behaviour
  {
    bool b = false;
    bool g (bool ga, bool gb)
    {
      a;
      return ga || gb;
    }

    [true]
      on e:
      {
        b = ! b;
        bool c = g (b, b);

        b = g (c, c);

        if(c)
        {
          a;
        }
      }
  }
}

interface U
{
  enum Status { Ok, Nok };

  in Status what;

  behaviour
  {
    Status s = Status.Ok;
    bool dummy = false;

    on what:
      {
        [s.Ok]
        {
          reply(Status.Ok);
        }
        [true]
        {
          reply(Status.Nok);
        }
      }
  }
}

component trip
{
  provides I i;
  requires U u;

  behaviour
  {
    typedef int[0..3] State;

    State state = 3;
    State c = 0;

    bool b = false;
    bool g (bool ga, bool gb)
    {
      i.a;
      return ga || gb;
    }

    on i.e:
    {
      [b || state == 0]
      {
        b = ! b;
        bool c = g (b, b);

        b = g (c, c);

        if(c)
        {
          i.a;
        }

        U.Status s = u.what;

        if(s == U.Status.Ok)
        {
          reply(I.Status.Yes);
        }
        if (! s.Ok)
        {
          reply(I.Status.No);
        }
      }
      [otherwise]
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
            if (c <= state + 1)
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
      [false] illegal;
    }
  }
}

component trap
{
  provides I i;
  requires U u;

  system
    {
      trip u;

      i <=> u.i;
      u.u <=> u;
    }
}
