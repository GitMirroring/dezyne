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

#include "component-imperative-c3.hh"

namespace component
{
  imperative::imperative()
  : state(States::States::I)
  , po_i()
  {
    po_i.in.e = asd::bind(&imperative::po_i_e, this);
  }

  void imperative::po_i_e()
  {
    std::cout << "imperative.po_i_e" << std::endl;
    if (state == States::I)
    {
      {
        po_i.out.f();
        po_i.out.g();
        po_i.out.h();
        state = States::II;

      }

    }
    else if (state == States::II)
    {
      {
        state = States::III;

      }

    }
    else if (state == States::III)
    {
      {
        po_i.out.f();
        po_i.out.g();
        po_i.out.g();
        po_i.out.f();
        state = States::IV;

      }

    }
    else if (state == States::IV)
    {
      {
        po_i.out.h();
        state = States::I;

      }

    }


  }






}
