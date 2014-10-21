// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

class requires_twice{


  irequires_twice p;
  irequires_twice once;
  irequires_twice twice;

  public requires_twice() {
    p = new irequires_twice();
    once = new irequires_twice();
    twice = new irequires_twice();
    p.getIn().e = new Action() {
      public void action() {
        p_e();
      }
    };
    once.getOut().a = new Action() {
      public void action() {
        once_a();
      }
    };
    twice.getOut().a = new Action() {
      public void action() {
        twice_a();
      }
    };
  };
  public void p_e() {
    System.err.println("requires_twice.p_e");
    {
      once.getIn().e.action();
      twice.getIn().e.action();
    }
  };

  public void once_a() {
    System.err.println("requires_twice.once_a");
    { }
  };

  public void twice_a() {
    System.err.println("requires_twice.twice_a");
    {
      p.getOut().a.action();
    }
  };

}
