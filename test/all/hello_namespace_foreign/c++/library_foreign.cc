// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2020, 2022, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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
//
#include "library_foreign.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

namespace library
{

foreign::foreign (dzn::locator const &locator)
  : dzn_meta{"", "foreign", 0, {}, {}, {[this]{w.dzn_check_bindings ();}}}
, dzn_runtime (locator.get<dzn::runtime> ())
, dzn_locator (locator)
, w ({{"w", &w, this, &dzn_meta}, {"", 0, 0, 0}})
{
  w.in.world = [&] {};
  w.in.world.set (this, &w, "world");
}
};
