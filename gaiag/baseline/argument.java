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

class argument{

  Boolean b;

  I i;

  public argument() {
    b = false;
    i = new I();
    i.getIn().e = new Action() {
      public void action() {
        i_e();
      }
    };
  };
  public void i_e() {
    System.err.println("argument.i_e");
    if (true) b = ! (b);
    Boolean c = this.g(b);
    b = this.g(c);
    if (c) {
      i.getOut().f.action();
    }
  };
  public Boolean g (Boolean gc) {
    i.getOut().f.action();
    return (gc || b);
  };

}
