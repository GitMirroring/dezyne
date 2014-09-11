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
  enum Status { Yes, No };

  in Status done;

  behaviour
  {
    bool dummy = false;
    void reply_fun ()
    {
      reply(Status.Yes);
    }
    void reply_fun_arg (Status s)
    {
      reply(s);
    }
    on done:
    {
      [true] { reply_fun(); }
      [true] { reply_fun_arg(Status.No); }
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
    void reply_fun ()
    {
      reply(Status.Ok);
    }
    void reply_fun_arg (Status s)
    {
      reply(s);
    }
    on what:
    {
      [true]
      {
        reply_fun();
      }
      [true]
      {
        reply_fun_arg(Status.Nok);
      }
    }
  }
}

component Reply3
{
  provides I i;
  requires U u;

  behaviour
  {
    bool dummy = false;
    void reply_fun ()
    {
      reply(I.Status.Yes);
    }
    void reply_fun_arg (I.Status s)
    {
      reply(s);
    }
    [true]
    {
      on i.done:
      {
        U.Status s = u.what;
        s = u.what;

        if(s == U.Status.Ok)
        {
          reply_fun();
        }
        else
        {
          reply_fun_arg(I.Status.No);
        }
      }
    }
  }
}
