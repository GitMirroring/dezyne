// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Rutger van Beusekom <rutger@dezyne.org>
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

#include "pump_twice.hh"

#include <dzn/locator.hh>
#include <dzn/pump.hh>
#include <dzn/runtime.hh>

int main()
{
  for(size_t i = 0; i < 2; ++i)
  {
    dzn::locator locator;
    dzn::runtime runtime;
    dzn::pump pump;
    pump_twice sut(locator.set(runtime).set(pump));
    sut.dzn_meta.name = "sut";
    sut.h.dzn_meta.require.name = "h";
    sut.h.out.world = [&]{};
    dzn::shell(pump, [&]{sut.h.in.hello();});
    pump.wait();
  }
}
