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

#include "collateral_blocking_backdoor.hh"

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
  collateral_blocking_backdoor sut (locator);
  sut.dzn_meta.name = "sut";
  sut.w.dzn_meta.provide.name = "w";
  sut.w.dzn_meta.provide.port = &sut.w;

  sut.w.in.hello = [&] {};

  // 1: run through left top to bottom and block
  auto f0 = std::async (std::launch::async, sut.left.in.hello);
  std::this_thread::sleep_for (std::chrono::milliseconds (100));

  // 2: collaterally block via right on middle
  auto f1 = std::async (std::launch::async, sut.right.in.hello);
  std::this_thread::sleep_for (std::chrono::milliseconds (100));

  // 3: release 1: left continues and ends
  //    release 2: right continues to bottom and blocks
  sut.w.out.world ();

  // 4: release 2: right continues and ends
  sut.w.out.world ();

  f0.wait ();
  f1.wait ();
  return 0;
}
