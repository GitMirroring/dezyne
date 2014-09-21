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

#ifndef COMPONENT_COMP_HH
#define COMPONENT_COMP_HH

#include "interface-IComp-c3.hh"
#include "interface-IDevice-c3.hh"

namespace component
{
  struct Comp
  {
    struct State
    {
      enum type
      {
        Uninitialized,
        Initialized,
        Error,
      };
    };
    State::type s;
    interface::IComp::result_t::type reply_IComp_result_t;
    interface::IDevice::result_t::type reply_IDevice_result_t;
    interface::IComp po_client;
    interface::IDevice po_device_A;

    Comp();
    interface::IComp::result_t::type po_client_initialize();
    interface::IComp::result_t::type po_client_recover();
    interface::IComp::result_t::type po_client_perform_actions();
  };
}
#endif
