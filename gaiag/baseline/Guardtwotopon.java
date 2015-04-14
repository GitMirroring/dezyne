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

class Guardtwotopon extends Component {

  Boolean b;

  IGuardtwotopon i;

  public Guardtwotopon(Runtime runtime) {this(runtime, "");};

  public Guardtwotopon(Runtime runtime, String name) {this(runtime, name, null);};

  public Guardtwotopon(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    b = false;
    i = new IGuardtwotopon();
    i.in.name = "i";
    i.in.self = this;
    b = false;
    i.in.e = new Action() {public void action() {Runtime.callIn(Guardtwotopon.this, new Action() {public void action() {i_e();}}, new Meta(Guardtwotopon.this.i, "e"));};};

    i.in.t = new Action() {public void action() {Runtime.callIn(Guardtwotopon.this, new Action() {public void action() {i_t();}}, new Meta(Guardtwotopon.this.i, "t"));};};

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
    i.out.a.action();
  };

}
