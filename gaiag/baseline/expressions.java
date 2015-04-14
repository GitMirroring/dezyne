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

class expressions extends Component {

  Integer state;
  Integer c;

  I i;

  public expressions(Runtime runtime) {this(runtime, "");};

  public expressions(Runtime runtime, String name) {this(runtime, name, null);};

  public expressions(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    state = 3;
    c = 0;
    i = new I();
    i.in.name = "i";
    i.in.self = this;
    state = 3;
    c = 0;
    i.in.e = new Action() {public void action() {Runtime.callIn(expressions.this, new Action() {public void action() {i_e();}}, new Meta(expressions.this.i, "e"));};};

  };
  public void i_e() {
    if (true) {
      if (state == 0) {
        state = 3;
        i.out.a.action();
      }
      else {
        state = state - 1;
        if (c < state) {
          c = c + 1;
        }
        else {
          if (c <= (state + 1)) {
            i.out.lo.action();
          }
          else {
            if (c > state) {
              i.out.hi.action();
            }
          }
        }
      }
    }
  };

}
