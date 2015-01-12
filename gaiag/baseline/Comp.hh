// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef DEZYNE_COMP_HH
#define DEZYNE_COMP_HH

#include "IComp.hh"
#include "IDevice.hh"


namespace dezyne
{
  struct locator;
  struct runtime;

  struct Comp
  {
    runtime& rt;
    struct State
    {
      enum type
      {
        Uninitialized, Initialized, Error
      };
    };
    Comp::State::type s;
    IComp::result_t::type reply_IComp_result_t;
    IDevice::result_t::type reply_IDevice_result_t;
    IComp client;
    IDevice device_A;

    Comp(const locator&);

    private:
    IComp::result_t::type client_initialize();
    IComp::result_t::type client_recover();
    IComp::result_t::type client_perform_actions();
  };
}
#endif // DEZYNE_COMP_HH
