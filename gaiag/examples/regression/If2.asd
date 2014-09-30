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

interface IIf2
{
  enum result { value };
  in void e;
  out result a;

  behaviour
  {
    bool b = false;
    result r = result.value;
    on e:
      {
        if (b)
        {
          result v = a;
        }
        else
          result v = a ();
        b = !b;
      }
  }
}

component If2
{
  provides IIf2 i;
  behaviour
  {
    bool b = false;
    IIf2.result r = IIf2.result.value;
    on i.e:
      {
        if (b)
        {
          IIf2.result v = i.a;
        }
        else
          IIf2.result v  = i.a;
        b = !b;
      }
  }
}
