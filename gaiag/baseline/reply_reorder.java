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

class reply_reorder extends Component {

  Boolean first;

  Provides p;
  Requires r;

  public reply_reorder(Runtime runtime) {this(runtime, "");};

  public reply_reorder(Runtime runtime, String name) {this(runtime, name, null);};

  public reply_reorder(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    first = true;
    p = new Provides();
    p.in.name = "p";
    p.in.self = this;
    first = true;
    r = new Requires();
    r.out.name = "r";
    r.out.self = this;
    p.in.start = new Action() {public void action() {Runtime.callIn(reply_reorder.this, new Action() {public void action() {p_start();}}, new Meta(reply_reorder.this.p, "start"));};};

    r.out.pong = new Action() {public void action() {Runtime.callOut(reply_reorder.this, new Action() {public void action() {r_pong();}}, new Meta(reply_reorder.this.r, "pong"));};};

  };
  public void p_start() {
    {
      r.in.ping.action();
    }
  };

  public void r_pong() {
    if (first) {
      p.out.busy.action();
      first = ! (first);
    }
    else if (! (first)) {
      p.out.finish.action();
      first = ! (first);
    }
  };

}
