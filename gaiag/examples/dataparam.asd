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

interface idataparam
{
  extern xint = $int$;
  enum Status {Yes, No};

  in void e (in xint i);
  out void a (out xint i);

  behaviour
  {
    xint i = 0;
    bool b = true;

    [i != true]
    {
      on e (pi):
      {
        b = pi;
        a (b);
      }
    }
  }
}

component dataparam
{
  provides idataparam port;

  behaviour
  {
    idataparam.xint i = 0;
    idataparam.Status s = idataparam.Status.Yes;
    bool b = true;

    idataparam.Status fun ()
    {
      return idataparam.Status.Yes;
    }

    [i != true]
      on port.e (pi):
      {
        idataparam.Status s = idataparam.Status.Yes;
        b = pi;
        port.a (b);
    }
  }
}
