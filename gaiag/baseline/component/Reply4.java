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

class Reply4{
  enum Status {
    Yes, No
  };

  Boolean dummy;
  I.Status reply_I_Status;

  U.Status reply_U_Status;


  I i;
  U u;

  public Reply4() {
    dummy = false;
    i = new I();
    u = new U();
    i.getIn().done = new ValuedAction<I.Status>() {
      public I.Status action() {
        return i_done();
      }
    };
  };
  public I.Status i_done() {
    System.err.println("Reply4.i_done");
    if (true) {
      {
        U.Status s = u.getIn().what.action();
        s = u.getIn().what.action();
        if (s == U.Status.Ok) {
          Status v = fun();
          if (v == Status.Yes) reply_I_Status = I.Status.Yes;
          else reply_I_Status = I.Status.No;
        }
        else {
          Status v = this.fun_arg(Status.No);
          if (v == Status.Yes) reply_I_Status = I.Status.Yes;
          else reply_I_Status = I.Status.No;
        }
      }
    }
    return reply_I_Status;
  };
  public Status fun () {
    return Status.Yes;
  };
  public Status fun_arg (Status s) {
    return s;
  };

}
