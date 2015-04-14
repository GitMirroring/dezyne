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

class Twotopon extends Component {

  Boolean b;

  ITwotopon i;

  public Twotopon(Runtime runtime) {this(runtime, "");};

  public Twotopon(Runtime runtime, String name) {this(runtime, name, null);};

  public Twotopon(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    b = false;
    i = new ITwotopon();
    i.in.name = "i";
    i.in.self = this;
    i.in.e = new Action() {public void action() {Runtime.callIn(Twotopon.this, new Action() {public void action() {i_e();}}, new Meta(Twotopon.this.i, "e"));};};

    i.in.t = new Action() {public void action() {Runtime.callIn(Twotopon.this, new Action() {public void action() {i_t();}}, new Meta(Twotopon.this.i, "t"));};};

  };
  public void i_e() {
    if (b) {
      i.out.a.action();
    }
    else if (! (b)) {
      i.out.a.action();
    }
  };

  public void i_t() {
    i.out.a.action();
  };

}
