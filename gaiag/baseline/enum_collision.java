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

class enum_collision extends Component {

  ienum_collision.Retval1 reply_ienum_collision_Retval1;

  ienum_collision.Retval2 reply_ienum_collision_Retval2;


  ienum_collision i;

  public enum_collision(Runtime runtime) {this(runtime, "");};

  public enum_collision(Runtime runtime, String name) {this(runtime, name, null);};

  public enum_collision(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    i = new ienum_collision();
    i.in.name = "i";
    i.in.self = this;
    i.in.foo = new ValuedAction<ienum_collision.Retval1>() {public ienum_collision.Retval1 action() {return Runtime.callIn(enum_collision.this, new ValuedAction<ienum_collision.Retval1>() {public ienum_collision.Retval1 action() {return i_foo();}}, new Meta(enum_collision.this.i, "foo"));};};

    i.in.bar = new ValuedAction<ienum_collision.Retval2>() {public ienum_collision.Retval2 action() {return Runtime.callIn(enum_collision.this, new ValuedAction<ienum_collision.Retval2>() {public ienum_collision.Retval2 action() {return i_bar();}}, new Meta(enum_collision.this.i, "bar"));};};

  };
  public ienum_collision.Retval1 i_foo() {
    reply_ienum_collision_Retval1 = ienum_collision.Retval1.OK;
    return reply_ienum_collision_Retval1;
  };

  public ienum_collision.Retval2 i_bar() {
    reply_ienum_collision_Retval2 = ienum_collision.Retval2.NOK;
    return reply_ienum_collision_Retval2;
  };

}
