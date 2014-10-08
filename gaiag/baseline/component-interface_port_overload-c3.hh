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

#ifndef COMPONENT_INTERFACE_PORT_OVERLOAD_HH
#define COMPONENT_INTERFACE_PORT_OVERLOAD_HH

#include "interface-I-c3.hh"


namespace component
{
  struct interface_port_overload
  {
    interface::I::R::type reply_I_R;
    interface::I po_I;

    interface_port_overload();
    interface::I::R::type po_I_e();
  };
}
#endif
