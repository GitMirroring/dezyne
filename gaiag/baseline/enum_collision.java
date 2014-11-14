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

class enum_collision{

  ienum_collision.Retval1 reply_ienum_collision_Retval1;

  ienum_collision.Retval2 reply_ienum_collision_Retval2;


  ienum_collision i;

  public enum_collision() {
    i = new ienum_collision();
    i.getIn().foo = new ValuedAction<ienum_collision.Retval1>() {
      public ienum_collision.Retval1 action() {
        return i_foo();
      }
    };
    i.getIn().bar = new ValuedAction<ienum_collision.Retval2>() {
      public ienum_collision.Retval2 action() {
        return i_bar();
      }
    };
  };
  public ienum_collision.Retval1 i_foo() {
    System.err.println("enum_collision.i_foo");
    reply_ienum_collision_Retval1 = ienum_collision.Retval1.OK;
    return reply_ienum_collision_Retval1;
  };

  public ienum_collision.Retval2 i_bar() {
    System.err.println("enum_collision.i_bar");
    reply_ienum_collision_Retval2 = ienum_collision.Retval2.NOK;
    return reply_ienum_collision_Retval2;
  };

}
