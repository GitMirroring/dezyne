// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "component-hide-c3.hh"

namespace component
{
  hide::hide()
  : b(false)
  , c(true)
  , po_i()
  {
    po_i.in.e = asd::bind(&hide::po_i_e, this);
  }

  void hide::po_i_e()
  {
    std::cout << "hide.po_i_e" << std::endl;
    if (true)
    {
      bool b = b;
      bool c = g(b, c);
      if (c)
      {
        po_i.out.f();

      }

    }

  }


  bool hide::g(bool b, bool d)
  {
    {
      bool b = d;
      bool d = c;
      po_i.out.f();
      return (b or d);

    }

  }
}
