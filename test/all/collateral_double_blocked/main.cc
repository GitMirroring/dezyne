// Dezyne --- Dezyne command line tools
//
// Copyright © 2022 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

#include "collateral_double_blocked.hh"

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
  // dzn::debug.rdbuf (std::clog.rdbuf ());

  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);
  collateral_double_blocked sut (locator);
  dzn::pump pump;
  locator.set(pump);

  sut.dzn_meta.name = "sut";

  sut.left.meta.require.name = "left";
  sut.left.meta.require.port = &sut.left;

  sut.middle.meta.require.name = "middle";
  sut.middle.meta.require.port = &sut.middle;

  sut.right.meta.require.name = "right";
  sut.right.meta.require.port = &sut.right;

  sut.r.meta.provide.name = "r";
  sut.r.meta.provide.port = &sut.r;

  sut.r.in.hello = [&]
  {
    dzn::trace (std::clog, sut.r.meta, "hello");
    dzn::trace_out (std::clog, sut.r.meta, "return");
  };

  // Let's pick just one trace of the 8 traces...
  std::string trace = read ();
  if (0);
  // trace
  else if (trace == "left.hello\nr.hello\nr.return\nmiddle.hello\nleft.return\nr.world\nmiddle.return")
  {
    pump (sut.left.in.hello);
    pump (sut.middle.in.hello);
    pump (sut.r.out.world);
  }
  else if (trace == "middle.hello\nr.hello\nr.return\nleft.hello\nmiddle.return\nr.world\nleft.return")
  {
    pump (sut.middle.in.hello);
    pump (sut.left.in.hello);
    pump (sut.r.out.world);
  }
  else
    throw ("missing trace");

  std::this_thread::sleep_for (std::chrono::milliseconds (100));

  return 0;
}
