// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

class Choice{
  enum State {
    Off, Idle, Busy
  };

  State s;

  IChoice c;

  public Choice() {
    s = State.Off;
    c = new IChoice();
    c.getIn().e = new Action() {
      public void action() {
        c_e();
      }
    };
  };
  public void c_e() {
    System.err.println("Choice.c_e");
    if (s == State.Off) {
      s = State.Idle;
      c.getOut().a.action();
    }
    else if (s == State.Idle) {
      s = State.Busy;
      c.getOut().a.action();
    }
    else if (s == State.Busy) {
      s = State.Idle;
      c.getOut().a.action();
    }
  };

}
