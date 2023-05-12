// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

#include "blocking_system_diamond.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int
main ()
{
  //dzn::debug.rdbuf (std::clog.rdbuf ());

  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);
  blocking_system_diamond sut (locator);
  sut.dzn_meta.name = "sut";
  sut.r_left.meta.provide.name = "r_left";
  sut.r_right.meta.provide.name = "r_right";

  sut.r_left.in.hello = [&] () {};
  sut.r_right.in.hello = [&] () {};

  // 1: run through left to bottom and block
  auto f = std::async (std::launch::async, sut.p.in.hello);
  std::this_thread::sleep_for (std::chrono::milliseconds (100));

  // 2: release: finish left,
  //    continue through right to bottom and block
  sut.r_left.out.world ();

  // 3: release: finish right and return
  sut.r_right.out.world ();

  f.wait ();

  return 0;
}
