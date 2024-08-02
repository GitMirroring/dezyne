// Dezyne --- Dezyne command line tools
//
// Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
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

#include "foreign_only_flush.hh"

#include <dzn/pump.hh>
#include <dzn/runtime.hh>

struct foreign: public skel::foreign
{
  int scenario;
  foreign (dzn::locator const& locator)
    : skel::foreign (locator)
    , scenario (0)
  {
    dzn_runtime.performs_flush (this) = true;
  }
  void port_hello (int i, double d)
  {
    switch (scenario++)
      {
      case 0:
      port_world (i, d);
      break;
    case 1:
      dzn_locator.get<dzn::pump> ().handle (reinterpret_cast<size_t> (this), 0, [this,i,d]
      {
        this->port_cruel (); this->port_world (i, d); this->dzn_runtime.flush (this);
      });
      break;
    case 2:
      port_cruel ();
      port_world (i, d);
      break;
    case 3:
      dzn_locator.get<dzn::pump> ().handle (reinterpret_cast<size_t> (this), 0, [this]
      {
        this->port_cruel (); this->dzn_runtime.flush (this);
      });
      break;
    case 4:
      port_world (i, d);
      break;
    case 5:
      dzn_locator.get<dzn::pump> ().handle (reinterpret_cast<size_t> (this), 0, [this,i,d]
      {
        this->port_world (i, d); this->dzn_runtime.flush (this);
      });
      break;
    default:
      assert (!"trace mismatch");
    }
  }
  void port_bye () {}
};
