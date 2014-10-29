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

interface ifunction2
{
  in void a;
  in void b;

  out void c;
  out void d;

  behaviour
  {
    bool f = false;

    bool vtoggle ()
    {
      if (f)
        c;
      return !f;
    }
    [true]
    {
      on a:
      {
	f = vtoggle();
      }
      on b:
      {
	f = vtoggle();
	f = vtoggle();
	d;
      }
    }
  }
}

component function2
{
  provides ifunction2 i;

  behaviour
  {
    bool f = false;

    bool vtoggle ()
    {
      if (f)
        i.c;
      return !f;
    }
    [true]
    {
      on i.a:
      {
	f = vtoggle();
      }
      on i.b:
      {
	f = vtoggle();
	f = vtoggle();
	i.d;
      }
    }
  }
}
