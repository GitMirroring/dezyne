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

class GuardedRequiredIllegal extends Component {

  Boolean c;

  Top t;
  Bottom b;

  public GuardedRequiredIllegal(Runtime runtime) {this(runtime, "");};

  public GuardedRequiredIllegal(Runtime runtime, String name) {this(runtime, name, null);};

  public GuardedRequiredIllegal(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    c = false;
    t = new Top();
    t.in.name = "t";
    t.in.self = this;
    c = false;
    b = new Bottom();
    b.out.name = "b";
    b.out.self = this;
    t.in.unguarded = new Action() {public void action() {Runtime.callIn(GuardedRequiredIllegal.this, new Action() {public void action() {t_unguarded();}}, new Meta(GuardedRequiredIllegal.this.t, "unguarded"));};};

    t.in.e = new Action() {public void action() {Runtime.callIn(GuardedRequiredIllegal.this, new Action() {public void action() {t_e();}}, new Meta(GuardedRequiredIllegal.this.t, "e"));};};

    b.out.f = new Action() {public void action() {Runtime.callOut(GuardedRequiredIllegal.this, new Action() {public void action() {b_f();}}, new Meta(GuardedRequiredIllegal.this.b, "f"));};};

  };
  public void t_unguarded() {
    { }
  };

  public void t_e() {
    if (! (c)) {
      c = true;
      b.in.e.action();
    }
    else if (c) { }
  };

  public void b_f() {
    if (! (c)) throw new RuntimeException("illegal");
    else if (c) {
      c = false;
    }
  };

}
