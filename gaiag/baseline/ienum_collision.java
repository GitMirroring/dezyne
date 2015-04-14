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

class ienum_collision extends Interface<ienum_collision.In, ienum_collision.Out> {
  enum Retval1 {
    OK, NOK
  };
  enum Retval2 {
    OK, NOK
  };
  class In extends Interface.In {
    ValuedAction<Retval1> foo;
    ValuedAction<Retval2> bar;
  }
  class Out extends Interface.Out {

  }
  public ienum_collision() {
    in = new In();
    out = new Out();
  }
}
