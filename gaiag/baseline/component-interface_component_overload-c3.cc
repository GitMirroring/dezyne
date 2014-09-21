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

#include "component-interface_component_overload-c3.hh"

namespace component
{
  interface_component_overload::interface_component_overload()
  : 
  po_interface_component_overload()
  {
    po_interface_component_overload.in.e = asd::bind(&interface_component_overload::po_interface_component_overload_e, this);
  }

  interface::interface_component_overload::R::type interface_component_overload::po_interface_component_overload_e()
  {
    std::cout << "interface_component_overload.po_interface_component_overload_e" << std::endl;
    {
      reply_interface_component_overload_R = interface::interface_component_overload::R::V;

    }

    return reply_interface_component_overload_R;

  }






}
