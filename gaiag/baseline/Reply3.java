// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

class Reply3{

  Boolean dummy;
  I.Status reply_I_Status;

  U.Status reply_U_Status;


  I i;
  U u;

  public Reply3() {
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
    System.err.println("Reply3.i_done");
    if (true) {
      U.Status s = u.getIn().what.action();
      s = u.getIn().what.action();
      if (s == U.Status.Ok) {
        reply_fun();
      }
      else {
        reply_fun_arg(I.Status.No);
      }
    }
    return reply_I_Status;
  };
  public void reply_fun () {
    reply_I_Status = I.Status.Yes;
  };
  public void reply_fun_arg (I.Status s) {
    reply_I_Status = s;
  };

}
