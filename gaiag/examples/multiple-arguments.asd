// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

interface I {
  in void start;
  behaviour {
  
    bool b = false;
  
    [true] on start: {}
  }
}

interface E {
  in void notok;
  
  behaviour {
    bool dummy = false;
    
    [true] on notok: illegal;
  }
}

component Comp {
  provides I i;
  requires E err;
  
  behaviour {
    enum T { e0, e1, e2, e3, e4 };
      
    T t = T.e0;
    
    bool b = false;
      
    void expect(T seen, T expected) {
      if (seen!=expected) {
        err.notok;
      }     
    }
      
    T f(T e, T f) {
      expect(e, T.e0);
      expect(f, T.e1);
      e = f;
      expect(e, T.e1);
      expect(f, T.e1);
      f = T.e2;
      expect(e, T.e1);
      expect(f, T.e2);
      e = T.e3;
      expect(e, T.e3);
      expect(f, T.e2);

      return e;
    }
  
    [true] on i.start: {
      T g = f(T.e0, T.e1);
      expect(g, T.e3);
    }
  }
}

