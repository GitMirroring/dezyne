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

class sugar{
  enum Enum {
    False, True
  };

  Enum s;

  I i;

  public sugar() {
    s = Enum.False;
    i = new I();
    i.getIn().e = new Action() {
      public void action() {
        i_e();
      }
    };
  };
  public void i_e() {
    System.err.println("sugar.i_e");
    if (s == Enum.False) if (s == Enum.False) i.getOut().a.action();
    else {
      Enum t = Enum.False;
      if (t == Enum.True) i.getOut().a.action();
    }
  };

}
