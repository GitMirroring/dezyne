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

interface I123
{
  enum Status { Yes, No };

  in Status done;

  behaviour
  {
    on done:
    {
      [true] { reply(Status.Yes); }
      [true] { reply(Status.No); }
    }
  }
}

interface U
{
  enum Status { Ok, Nok };

  in Status what;

  behaviour
  {
    on what:
    {
      [true]
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

component C1
{
  provides I123 i;
  requires U u;

  behaviour
  {
    [true]
    {
      on i.done:
      {
        U.Status s = u.what;

        // if(s == u.Status.Ok)
        // {
        //   reply(i.Status.Yes);
        // }
        // else
        // {
        reply(I123.Status.No);
        // }
      }
    }
  }
}
