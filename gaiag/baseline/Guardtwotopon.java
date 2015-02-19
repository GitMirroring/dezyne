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

class Guardtwotopon{

  Boolean b;

  IGuardtwotopon i;

  public Guardtwotopon() {
    b = false;
    i = new IGuardtwotopon();
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
    System.err.println("Guardtwotopon.i_e");
    if (true && b) {
      i.getOut().a.action();
    }
    else if (true && ! (b)) {
      Boolean c = true;
      if (c) i.getOut().a.action();
    }
  };

  public void i_t() {
    System.err.println("Guardtwotopon.i_t");
    i.getOut().a.action();
  };

}
