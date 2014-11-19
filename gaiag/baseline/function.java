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

class function{

  Boolean f;

  I i;

  public function() {
    f = false;
    i = new I();
    i.getIn().a = new Action() {
      public void action() {
        i_a();
      }
    };
    i.getIn().b = new Action() {
      public void action() {
        i_b();
      }
    };
  };
  public void i_a() {
    System.err.println("function.i_a");
    if (true) {
      toggle();
    }
  };

  public void i_b() {
    System.err.println("function.i_b");
    if (true) {
      toggle();
      toggle();
      i.getOut().d.action();
    }
  };
  public void toggle () {
    if (f) {
      i.getOut().c.action();
    }
    f = ! (f);
  };

}
