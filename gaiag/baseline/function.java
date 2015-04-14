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

class function extends Component {

  Boolean f;

  I i;

  public function(Runtime runtime) {this(runtime, "");};

  public function(Runtime runtime, String name) {this(runtime, name, null);};

  public function(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    f = false;
    i = new I();
    i.in.name = "i";
    i.in.self = this;
    f = false;
    i.in.a = new Action() {public void action() {Runtime.callIn(function.this, new Action() {public void action() {i_a();}}, new Meta(function.this.i, "a"));};};

    i.in.b = new Action() {public void action() {Runtime.callIn(function.this, new Action() {public void action() {i_b();}}, new Meta(function.this.i, "b"));};};

  };
  public void i_a() {
    if (true) {
      {
        toggle();
      }
    }
  };

  public void i_b() {
    if (true) {
      {
        toggle();
        toggle();
        i.out.d.action();
      }
    }
  };
  public void toggle () {
    if (f) {
      i.out.c.action();
    }
    f = ! (f);
  };

}
