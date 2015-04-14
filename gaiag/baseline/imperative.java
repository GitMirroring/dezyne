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

class imperative extends Component {
  enum States {
    I, II, III, IV
  };

  States state;

  iimperative i;

  public imperative(Runtime runtime) {this(runtime, "");};

  public imperative(Runtime runtime, String name) {this(runtime, name, null);};

  public imperative(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    state = States.I;
    i = new iimperative();
    i.in.name = "i";
    i.in.self = this;
    state = States.I;
    i.in.e = new Action() {public void action() {Runtime.callIn(imperative.this, new Action() {public void action() {i_e();}}, new Meta(imperative.this.i, "e"));};};

  };
  public void i_e() {
    if (state == States.I) {
      i.out.f.action();
      i.out.g.action();
      i.out.h.action();
      state = States.II;
    }
    else if (state == States.II) {
      state = States.III;
    }
    else if (state == States.III) {
      i.out.f.action();
      i.out.g.action();
      i.out.g.action();
      i.out.f.action();
      state = States.IV;
    }
    else if (state == States.IV) {
      i.out.h.action();
      state = States.I;
    }
  };

}
