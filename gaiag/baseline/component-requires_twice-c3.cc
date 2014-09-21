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

#include "component-requires_twice-c3.hh"

namespace component
{
  requires_twice::requires_twice()
  : 
  po_p()
  , po_once()
  , po_twice()
  {
    po_p.in.e = asd::bind(&requires_twice::po_p_e, this);
    po_once.out.a = asd::bind(&requires_twice::po_once_a, this);
    po_twice.out.a = asd::bind(&requires_twice::po_twice_a, this);
  }

  void requires_twice::po_p_e()
  {
    std::cout << "requires_twice.po_p_e" << std::endl;
    {
      po_once.out.a();
      po_twice.out.a();

    }


  }

  void requires_twice::po_once_a()
  {
    std::cout << "requires_twice.po_once_a" << std::endl;


  }

  void requires_twice::po_twice_a()
  {
    std::cout << "requires_twice.po_twice_a" << std::endl;


  }






}
