// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef COMPONENT_REPLY7_HH
#define COMPONENT_REPLY7_HH

#include "interface-IReply7-c3.hh"
#include "interface-IReply7-c3.hh"


namespace component
{
  struct Reply7
  {
    interface::IReply7::E::type reply_IReply7_E;
    interface::IReply7 po_p;
    interface::IReply7 po_r;

    Reply7();
    interface::IReply7::E::type po_p_foo();
    interface::IReply7::E::type f();
  };
}
#endif
