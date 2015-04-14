// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

class Guardthreetopon extends Component {

  Boolean b;

  IGuardthreetopon i;
  RGuardthreetopon r;

  public Guardthreetopon(Runtime runtime) {this(runtime, "");};

  public Guardthreetopon(Runtime runtime, String name) {this(runtime, name, null);};

  public Guardthreetopon(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    b = false;
    i = new IGuardthreetopon();
    i.in.name = "i";
    i.in.self = this;
    r = new RGuardthreetopon();
    r.out.name = "r";
    r.out.self = this;
    i.in.e = new Action() {public void action() {Runtime.callIn(Guardthreetopon.this, new Action() {public void action() {i_e();}}, new Meta(Guardthreetopon.this.i, "e"));};};

    i.in.t = new Action() {public void action() {Runtime.callIn(Guardthreetopon.this, new Action() {public void action() {i_t();}}, new Meta(Guardthreetopon.this.i, "t"));};};

    i.in.s = new Action() {public void action() {Runtime.callIn(Guardthreetopon.this, new Action() {public void action() {i_s();}}, new Meta(Guardthreetopon.this.i, "s"));};};

    r.out.a = new Action() {public void action() {Runtime.callOut(Guardthreetopon.this, new Action() {public void action() {r_a();}}, new Meta(Guardthreetopon.this.r, "a"));};};

  };
  public void i_e() {
    if (true && b) {
      i.out.a.action();
    }
    else if (true && ! (b)) {
      V<Boolean> c = new V <Boolean>(true);
      if (c.v) i.out.a.action();
    }
  };

  public void i_t() {
    if (b) i.out.a.action();
    else if (! (b)) i.out.a.action();
  };

  public void i_s() {
    i.out.a.action();
  };

  public void r_a() {
    { }
  };

}
