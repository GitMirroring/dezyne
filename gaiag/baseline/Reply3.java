// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

class Reply3 extends Component {

  Boolean dummy;
  I.Status reply_I_Status;

  U.Status reply_U_Status;


  I i;
  U u;

  public Reply3(Runtime runtime) {this(runtime, "");};

  public Reply3(Runtime runtime, String name) {this(runtime, name, null);};

  public Reply3(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    dummy = false;
    i = new I();
    i.in.name = "i";
    i.in.self = this;
    dummy = false;
    u = new U();
    u.out.name = "u";
    u.out.self = this;
    i.in.done = new ValuedAction<I.Status>() {public I.Status action() {return Runtime.callIn(Reply3.this, new ValuedAction<I.Status>() {public I.Status action() {return i_done();}}, new Meta(Reply3.this.i, "done"));};};

  };
  public I.Status i_done() {
    if (true) {
      V<U.Status> s = new V <U.Status>(u.in.what.action());
      s.v = u.in.what.action();
      if (s.v == U.Status.Ok) {
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
  public void reply_fun_arg (final I.Status s) {
    reply_I_Status = s;
  };

}
