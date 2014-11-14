// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

class double_out_on_modeling{
  enum State {
    First, Second
  };

  State state;

  I p;
  I r;

  public double_out_on_modeling() {
    state = State.First;
    p = new I();
    r = new I();
    p.getIn().start = new Action() {
      public void action() {
        p_start();
      }
    };
    r.getOut().foo = new Action() {
      public void action() {
        r_foo();
      }
    };
    r.getOut().bar = new Action() {
      public void action() {
        r_bar();
      }
    };
  };
  public void p_start() {
    System.err.println("double_out_on_modeling.p_start");
    if (state == State.First) {
      {
        r.getIn().start.action();
        state = State.Second;
      }
    }
    else if (state == State.Second) {
      assert(false);
    }
  };

  public void r_foo() {
    System.err.println("double_out_on_modeling.r_foo");
    if (state == State.First) {
      assert(false);
    }
    else if (state == State.Second) {
      p.getOut().foo.action();
    }
  };

  public void r_bar() {
    System.err.println("double_out_on_modeling.r_bar");
    if (state == State.First) {
      assert(false);
    }
    else if (state == State.Second) {
      {
        p.getOut().bar.action();
        state = State.First;
      }
    }
  };

}
