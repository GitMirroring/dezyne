// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <foreign_handwritten.hh>

Foreign::Foreign (const dzn::locator &dzn_locator)
  : dzn_meta{"", "Foreign", 0, {}, {}, {[this]{w.dzn_check_bindings ();}}}
, dzn_runtime (dzn_locator.get<dzn::runtime> ())
, dzn_locator (dzn_locator)
, w ({{"w", &w, this, &dzn_meta}, {"", 0, 0, 0}})
{
  dzn_meta.require = {};
  w.in.world = [&] ()
  {
    return dzn::wrap_in (this, this->w, [ = ] ()
    {
      return w_world ();
    }, "world");
  };
}

void Foreign::w_world () {}
