// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

class reply_reorder{

  Boolean first;

  Provides p;
  Requires r;

  public reply_reorder() {
    first = true;
    p = new Provides();
    r = new Requires();
    p.getIn().start = new Action() {
      public void action() {
        p_start();
      }
    };
    r.getOut().pong = new Action() {
      public void action() {
        r_pong();
      }
    };
  };
  public void p_start() {
    System.err.println("reply_reorder.p_start");
    {
      r.getIn().ping.action();
    }
  };

  public void r_pong() {
    System.err.println("reply_reorder.r_pong");
    {
      if (first) {
        p.getOut().busy.action();
        first = ! (first);
      }
      if (! (first)) {
        p.getOut().finish.action();
        first = ! (first);
      }
    }
  };

}
