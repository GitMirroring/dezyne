// Dezyne --- Dezyne command line tools
//
// Copyright © 2022, 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

#include "collateral_blocking_bridges.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

std::string
read ()
{
  std::string str;
  {
    std::string line;
    while (std::cin >> line)
      str += (str.empty () ? "" : "\n") + line;
  }
  return str;
}

int
main ()
{
  //dzn::debug.rdbuf (std::clog.rdbuf ());

  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);
  collateral_blocking_bridges sut (locator);

  sut.top_w.in.hello = [&] {};
  sut.middle_w.in.hello = [&] {};
  sut.bottom_w.in.hello = [&] {};

  auto f = std::async (std::launch::async, sut.h.in.hello); // 1: run through top to middle and block
  std::this_thread::sleep_for (std::chrono::milliseconds (100));
  std::string trace = read ();
  if (0);
  // trace
  else if (trace == "h.hello\n<defer>\ntop_w.hello\ntop_w.return\n<defer>\nmiddle_w.hello\nmiddle_w.return\ntop_w.world\nmiddle_w.world\n<defer>\nbottom_w.hello\nbottom_w.return\nbottom_w.world\nh.return")
    {
      sut.top_w.out.world ();    // 2: collaterally blocks on top
      sut.middle_w.out.world (); // 3: releases 1; 1 continues and blocks on bottom
      std::this_thread::sleep_for (std::chrono::milliseconds (100));
      sut.bottom_w.out.world (); // 4: releases 1 again then 2 finishes
    }
  // trace.1
  else if (trace == "h.hello\n<defer>\ntop_w.hello\ntop_w.return\n<defer>\nmiddle_w.hello\nmiddle_w.return\nmiddle_w.world\n<defer>\nbottom_w.hello\nbottom_w.return\ntop_w.world\nbottom_w.world\nh.return")
    {
      sut.middle_w.out.world (); // 2: releases 1; 1 continues and blocks on bottom
      std::this_thread::sleep_for (std::chrono::milliseconds (100));
      sut.top_w.out.world ();    // 3: collaterally blocks on top
      sut.bottom_w.out.world (); // 4: releases 1 again then 2 finishes
    }
  // trace.2
  else if (trace == "h.hello\n<defer>\ntop_w.hello\ntop_w.return\n<defer>\nmiddle_w.hello\nmiddle_w.return\nmiddle_w.world\n<defer>\nbottom_w.hello\nbottom_w.return\nbottom_w.world\ntop_w.world\nh.return")
    {
      sut.middle_w.out.world (); // 2: releases 1; 1 continues and blocks on bottom
      std::this_thread::sleep_for (std::chrono::milliseconds (100));
      sut.bottom_w.out.world (); // 3: releases 1 again then 2 finishes
      sut.top_w.out.world ();    // 2: releases 1, finishes
      // 1 finished
    }
  else
    {
      std::clog << "missing trace" << std::endl;
      return 1;
    }

  f.wait ();

  return 0;
}
