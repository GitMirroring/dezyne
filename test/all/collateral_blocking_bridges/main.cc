// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

#include "collateral_blocking_bridges.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int
main ()
{
  dzn::locator loc;
  dzn::runtime rt;
  loc.set (rt);
  collateral_blocking_bridges sut (loc);
  sut.dzn_meta.name = "sut";

  sut.top_w.meta.provide.name = "top_w";
  sut.top_w.meta.provide.port = &sut.top_w;

  sut.middle_w.meta.provide.name = "middle_w";
  sut.middle_w.meta.provide.port = &sut.middle_w;

  sut.bottom_w.meta.provide.name = "bottom_w";
  sut.bottom_w.meta.provide.port = &sut.bottom_w;

  sut.top_w.in.hello = [&]
  {
    dzn::trace(std::clog, sut.top_w.meta, "hello");
    dzn::trace_out(std::clog, sut.top_w.meta, "return");
  };
  sut.middle_w.in.hello = [&]
  {
    dzn::trace(std::clog, sut.middle_w.meta, "hello");
    dzn::trace_out(std::clog, sut.middle_w.meta, "return");
  };
  sut.bottom_w.in.hello = [&]
  {
    dzn::trace(std::clog, sut.bottom_w.meta, "hello");
    dzn::trace_out(std::clog, sut.bottom_w.meta, "return");
  };

  auto f = std::async(std::launch::async, sut.h.in.hello); // 1: run through top to middle and block
  std::this_thread::sleep_for(std::chrono::milliseconds(100));

  sut.top_w.out.world();    // 2: collaterally blocks on top
  sut.middle_w.out.world(); // 3: releases 1; 1 continues and blocks on bottom
  sut.bottom_w.out.world(); // 4: releases 1 again then 2 finishes

  f.wait();

  return 0;
}
