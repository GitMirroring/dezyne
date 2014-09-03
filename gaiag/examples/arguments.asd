// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Gaiag.
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

interface I
{
  in void e;
  out void f;

  behaviour
  {
    bool ma = false;
    bool mb = false;

    bool g (bool pa) 
    {
      bool gb = pa;
      f; 
      return gb; 
    }

    bool gg (bool pa, bool pb) 
    {
      bool ggb = pa && pb;
      f; 
      return ggb; 
    }

    [true]
    on e:
    {
      ma = ! ma;
      {
        bool lc = g (ma, mb);
        bool ld = false;
        
        ma = g (lc);
        mb = g (ma, ld);
        
        {
          if (lc)
            {
              f;
            }
        }
        
        mb = !ld;
      }
    }
  }
}


component arguments
{
  provides I i;

  behaviour
  {
    bool b = false;
    bool g (bool c) { i.f; return c; }

    [true]
    on i.e:
    {
      b = ! b;
      bool c = g (b);

      b = g (c);

      if(c)
      {
        i.f;
      }
    }
  }
}
