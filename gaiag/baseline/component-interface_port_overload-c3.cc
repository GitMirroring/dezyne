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

#include "component-interface_port_overload-c3.hh"

namespace component
{
  interface_port_overload::interface_port_overload()
  : 
  po_I()
  {
    po_I.in.e = asd::bind(&interface_port_overload::po_I_e, this);
  }

  interface::I::R::type interface_port_overload::po_I_e()
  {
    std::cout << "interface_port_overload.po_I_e" << std::endl;
    {
      reply_I_R = interface::I::R::V;

    }

    return reply_I_R;

  }






}
