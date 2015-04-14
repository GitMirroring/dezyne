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

class incomplete_with_modeling_event extends Component {


  iincomplete_with_modeling_event p;
  iincomplete_with_modeling_event r;

  public incomplete_with_modeling_event(Runtime runtime) {this(runtime, "");};

  public incomplete_with_modeling_event(Runtime runtime, String name) {this(runtime, name, null);};

  public incomplete_with_modeling_event(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    p = new iincomplete_with_modeling_event();
    p.in.name = "p";
    p.in.self = this;
    r = new iincomplete_with_modeling_event();
    r.out.name = "r";
    r.out.self = this;
    p.in.e = new Action() {public void action() {Runtime.callIn(incomplete_with_modeling_event.this, new Action() {public void action() {p_e();}}, new Meta(incomplete_with_modeling_event.this.p, "e"));};};

    r.out.a = new Action() {public void action() {Runtime.callOut(incomplete_with_modeling_event.this, new Action() {public void action() {r_a();}}, new Meta(incomplete_with_modeling_event.this.r, "a"));};};

  };
  public void p_e() {
    { }
  };

  public void r_a() {
    p.out.a.action();
  };

}
