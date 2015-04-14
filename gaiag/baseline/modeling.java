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

class modeling extends Component {


  dummy p;
  imodeling r;

  public modeling(Runtime runtime) {this(runtime, "");};

  public modeling(Runtime runtime, String name) {this(runtime, name, null);};

  public modeling(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    p = new dummy();
    p.in.name = "p";
    p.in.self = this;
    r = new imodeling();
    r.out.name = "r";
    r.out.self = this;
    p.in.e = new Action() {public void action() {Runtime.callIn(modeling.this, new Action() {public void action() {p_e();}}, new Meta(modeling.this.p, "e"));};};

    r.out.f = new Action() {public void action() {Runtime.callOut(modeling.this, new Action() {public void action() {r_f();}}, new Meta(modeling.this.r, "f"));};};

  };
  public void p_e() {
    r.in.e.action();
  };

  public void r_f() {
    { }
  };

}
