// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
  out void f;

  behaviour
  {
    bool b = false;
    bool g (bool gc) { f; return gc || b; }

    [true]
    on e:
    {
      b = ! b;
      bool c = g (b);

      b = g (c);

      if(c)
      {
        f;
      }
    }
  }
}


component argument
{
  provides I i;

  behaviour
  {
    bool b = false;
    bool g (bool gc) { i.f; return gc || b; }

    [true]
    on i.e:
    {
      b = ! b;
      bool c = g (b);

      b = g (c);

      if(c)
      {
        i.f;
      }
    }
  }
}
