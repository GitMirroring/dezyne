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

class requires_twice extends Component {


  irequires_twice p;
  irequires_twice once;
  irequires_twice twice;

  public requires_twice(Runtime runtime) {this(runtime, "");};

  public requires_twice(Runtime runtime, String name) {this(runtime, name, null);};

  public requires_twice(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    p = new irequires_twice();
    p.in.name = "p";
    p.in.self = this;
    once = new irequires_twice();
    once.out.name = "once";
    once.out.self = this;
    twice = new irequires_twice();
    twice.out.name = "twice";
    twice.out.self = this;
    p.in.e = new Action() {public void action() {Runtime.callIn(requires_twice.this, new Action() {public void action() {p_e();}}, new Meta(requires_twice.this.p, "e"));};};

    once.out.a = new Action() {public void action() {Runtime.callOut(requires_twice.this, new Action() {public void action() {once_a();}}, new Meta(requires_twice.this.once, "a"));};};

    twice.out.a = new Action() {public void action() {Runtime.callOut(requires_twice.this, new Action() {public void action() {twice_a();}}, new Meta(requires_twice.this.twice, "a"));};};

  };
  public void p_e() {
    {
      once.in.e.action();
      twice.in.e.action();
    }
  };

  public void once_a() {
    { }
  };

  public void twice_a() {
    {
      p.out.a.action();
    }
  };

}
