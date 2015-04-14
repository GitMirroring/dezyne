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

class argument2 extends Component {

  Boolean b;

  I i;

  public argument2(Runtime runtime) {this(runtime, "");};

  public argument2(Runtime runtime, String name) {this(runtime, name, null);};

  public argument2(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    b = false;
    i = new I();
    i.in.name = "i";
    i.in.self = this;
    i.in.e = new Action() {public void action() {Runtime.callIn(argument2.this, new Action() {public void action() {i_e();}}, new Meta(argument2.this.i, "e"));};};

  };
  public void i_e() {
    if (true) {
      b = ! (b);
      V<Boolean> c = new V <Boolean>(this.g(b, b));
      b = this.g(c.v, c.v);
      if (c.v) {
        i.out.f.action();
      }
    }
  };
  public Boolean g (final Boolean ga, final Boolean gb) {
    i.out.f.action();
    return (ga || gb);
  };

}
