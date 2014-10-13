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

#ifndef COMPONENT_REPLY4_HH
#define COMPONENT_REPLY4_HH

#include "interface-I-c3.hh"
#include "interface-U-c3.hh"


namespace component
{
  struct Reply4
  {
    struct Status
    {
      enum type
      {
        Yes, No
      };
    };
    bool dummy;
    interface::I::Status::type reply_I_Status;
    interface::U::Status::type reply_U_Status;
    interface::I i;
    interface::U u;

    Reply4();
    interface::I::Status::type i_done();
    Reply4::Status::type fun();
    Reply4::Status::type fun_arg(Reply4::Status::type s);
  };
}
#endif
