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

class Reply7 extends Component {

  IReply7.E reply_IReply7_E;


  IReply7 p;
  IReply7 r;

  public Reply7(Runtime runtime) {this(runtime, "");};

  public Reply7(Runtime runtime, String name) {this(runtime, name, null);};

  public Reply7(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    p = new IReply7();
    p.in.name = "p";
    p.in.self = this;
    r = new IReply7();
    r.out.name = "r";
    r.out.self = this;
    p.in.foo = new ValuedAction<IReply7.E>() {public IReply7.E action() {return Runtime.callIn(Reply7.this, new ValuedAction<IReply7.E>() {public IReply7.E action() {return p_foo();}}, new Meta(Reply7.this.p, "foo"));};};

  };
  public IReply7.E p_foo() {
    f();
    return reply_IReply7_E;
  };
  public void f () {
    V<IReply7.E> v = new V <IReply7.E>(r.in.foo.action());
    reply_IReply7_E = v.v;
  };

}
