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

class If extends Component {

  Boolean t;

  I i;

  public If(Runtime runtime) {this(runtime, "");};

  public If(Runtime runtime, String name) {this(runtime, name, null);};

  public If(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    t = false;
    i = new I();
    i.in.name = "i";
    i.in.self = this;
    i.in.a = new Action() {public void action() {Runtime.callIn(If.this, new Action() {public void action() {i_a();}}, new Meta(If.this.i, "a"));};};

  };
  public void i_a() {
    {
      if (t) {
        i.out.b.action();
      }
      else {
        i.out.c.action();
      }
      t = ! (t);
    }
  };

}
