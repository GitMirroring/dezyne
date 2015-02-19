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

class GuardedRequiredIllegal{

  Boolean c;

  Top t;
  Bottom b;

  public GuardedRequiredIllegal() {
    c = false;
    t = new Top();
    b = new Bottom();
    t.getIn().unguarded = new Action() {
      public void action() {
        t_unguarded();
      }
    };
    t.getIn().e = new Action() {
      public void action() {
        t_e();
      }
    };
    b.getOut().f = new Action() {
      public void action() {
        b_f();
      }
    };
  };
  public void t_unguarded() {
    System.err.println("GuardedRequiredIllegal.t_unguarded");
    { }
  };

  public void t_e() {
    System.err.println("GuardedRequiredIllegal.t_e");
    if (! (c)) {
      c = true;
      b.getIn().e.action();
    }
    else if (c) { }
  };

  public void b_f() {
    System.err.println("GuardedRequiredIllegal.b_f");
    if (! (c)) assert(false);
    else if (c) {
      c = false;
    }
  };

}
