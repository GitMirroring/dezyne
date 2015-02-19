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

class Twotopon{

  Boolean b;

  ITwotopon i;

  public Twotopon() {
    b = false;
    i = new ITwotopon();
    i.getIn().e = new Action() {
      public void action() {
        i_e();
      }
    };
    i.getIn().t = new Action() {
      public void action() {
        i_t();
      }
    };
  };
  public void i_e() {
    System.err.println("Twotopon.i_e");
    if (b) {
      i.getOut().a.action();
    }
    else if (! (b)) {
      i.getOut().a.action();
    }
  };

  public void i_t() {
    System.err.println("Twotopon.i_t");
    i.getOut().a.action();
  };

}
