// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

class Choice extends Component {
  enum State {
    Off, Idle, Busy
  };

  State s;

  IChoice c;

  public Choice(Runtime runtime) {this(runtime, "");};

  public Choice(Runtime runtime, String name) {this(runtime, name, null);};

  public Choice(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    s = State.Off;
    c = new IChoice();
    c.in.name = "c";
    c.in.self = this;
    s = State.Off;
    c.in.e = new Action() {public void action() {Runtime.callIn(Choice.this, new Action() {public void action() {c_e();}}, new Meta(Choice.this.c, "e"));};};

  };
  public void c_e() {
    if (s == State.Off) {
      s = State.Idle;
      c.out.a.action();
    }
    else if (s == State.Idle) {
      s = State.Busy;
      c.out.a.action();
    }
    else if (s == State.Busy) {
      s = State.Idle;
      c.out.a.action();
    }
  };

}
