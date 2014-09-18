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

interface I
{
  enum Status { Yes, No };

  in Status done;

  behaviour
  {
    bool dummy = false;
    Status fun ()
    {
      return Status.Yes;
    }
    Status fun_arg (Status s)
    {
      return s;
    }
    on done:
    {
      [true] { Status v = fun(); reply (v); }
      [true] { Status v = fun_arg (Status.No); reply (v); }
    }
  }
}

interface U
{
  enum Status { Ok, Nok };

  in Status what;

  behaviour
  {
    bool dummy = false;
    Status fun ()
    {
      return Status.Ok;
    }
    Status fun_arg (Status s)
    {
      return s;
    }
    on what:
    {
      [true]
      {
        Status v = fun(); reply (v);
      }
      [true]
      {
        Status v = fun_arg(Status.Ok); reply (v);
      }
    }
  }
}

component Reply4
{
  provides I i;
  requires U u;

  behaviour
  {
    enum Status {Yes, No};

    bool dummy = false;
    Status fun ()
    {
      return Status.Yes;
    }
    Status fun_arg (Status s)
    {
      return s;
    }
    [true]
    {
      on i.done:
      {
        U.Status s = u.what;
        s = u.what;

        if(s == U.Status.Ok)
        {
          Status v = fun();
          if(v == Status.Yes) reply (I.Status.Yes);
          else reply (I.Status.No);
        }
        else
        {
          Status v = fun_arg(Status.No);
          if(v == Status.Yes) reply (I.Status.Yes);
          else reply (I.Status.No);
        }
      }
    }
  }
}
