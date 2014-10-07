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

#ifndef COMPONENT_REPLY5_HH
#define COMPONENT_REPLY5_HH

#include "interface-I-c3.hh"
#include "interface-U-c3.hh"


namespace component
{
  struct Reply5
  {
    bool dummy;
    interface::I::Status::type reply_I_Status;
    interface::U::Status::type reply_U_Status;
    interface::I po_i;
    interface::U po_u;

    Reply5();
    interface::I::Status::type po_i_done();
    interface::I::Status::type fun();
    interface::I::Status::type fun_arg(interface::I::Status::type s);
  };
}
#endif
