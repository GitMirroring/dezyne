// Dezyne --- Dezyne command line tools
//
// Copyright © 2022, 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
// Copyright © 2022 Paul Hoogendijk <paul@dezyne.org>
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

#include "compliance_blocking_double_release2.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int
main ()
{
  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);
  compliance_blocking_double_release2 sut (locator);

  dzn::check_bindings (sut);

  auto f0 = std::async (std::launch::async, sut.block0.in.hello);
  std::this_thread::sleep_for (std::chrono::milliseconds (100));
  auto f1 = std::async (std::launch::async, sut.block1.in.hello);
  std::this_thread::sleep_for (std::chrono::milliseconds (100));
  sut.release.in.hello ();

  f0.wait ();
  f1.wait ();

  return 0;
}
