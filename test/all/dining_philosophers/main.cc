// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

#include "dining_philosophers.hh"

int
main ()
{
  dzn::locator locator;
  dzn::runtime runtime;
  dining_philosophers sut (locator.set (runtime));
  sut.dzn_meta.name = "sut";

  sut.m.in.start ();

  std::this_thread::sleep_for (std::chrono::milliseconds (1000));

  sut.m.in.stop ();
}
