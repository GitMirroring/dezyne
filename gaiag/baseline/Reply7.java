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

class Reply7{

  IReply7.E reply_IReply7_E;


  IReply7 p;
  IReply7 r;

  public Reply7() {
    p = new IReply7();
    r = new IReply7();
    p.getIn().foo = new ValuedAction<IReply7.E>() {
      public IReply7.E action() {
        return p_foo();
      }
    };
  };
  public IReply7.E p_foo() {
    System.err.println("Reply7.p_foo");
    f();
    return reply_IReply7_E;
  };
  public void f () {
    IReply7.E v = r.getIn().foo.action();
    reply_IReply7_E = v;
  };

}
