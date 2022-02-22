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

#include "collateral_blocking_double_release.hh"

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
  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);
  collateral_blocking_double_release sut (locator);
  dzn::pump pump;
  locator.set(pump);

  sut.dzn_meta.name = "sut";

  sut.block0.meta.require.name = "block0";
  sut.block0.meta.require.port = &sut.block0;

  sut.block1.meta.require.name = "block1";
  sut.block1.meta.require.port = &sut.block1;

  sut.release.meta.require.name = "release";
  sut.release.meta.require.port = &sut.release;

  sut.w.meta.provide.name = "w";
  sut.w.meta.provide.port = &sut.w;

  sut.w.in.hello = [&]
  {
    dzn::trace (std::clog, sut.w.meta, "hello");
    dzn::trace_out (std::clog, sut.w.meta, "return");
  };

  sut.w.in.cruel = [&]
  {
    dzn::trace (std::clog, sut.w.meta, "cruel");
    dzn::trace_out (std::clog, sut.w.meta, "return");
  };

  // Let's just pick one trace
  std::string trace = read ();
  if (0);
  // trace
  else if (trace == "block1.hello\nw.hello\nw.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.hello\nw.hello\nw.return\nblock1.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.return")
  {
    pump ([&] {sut.block1.in.hello (); sut.release.in.hello ();});
    pump ([&] {sut.release.in.hello (); sut.block0.in.hello ();});
  }
  else if (trace == "block0.hello\nw.hello\nw.return\nblock1.hello\nw.hello\nw.return\nw.world\nw.cruel\nw.return\nblock0.return\nblock1.return")
  {
    pump ([&] {sut.block0.in.hello ();});
    pump ([&] {sut.block1.in.hello ();});
    pump ([&] {sut.w.out.world ();});
  }
  else if (trace == "block0.hello\nw.hello\nw.return\nblock1.hello\nw.hello\nw.return\nrelease.hello\nw.cruel\nw.return\nrelease.return\nblock0.return\nblock1.return")
  {
    pump ([&] {sut.block0.in.hello ();});
    pump ([&] {sut.block1.in.hello ();});
    pump ([&] {sut.release.in.hello ();});
  }
  else
  {
    std::clog << "missing trace" << std::endl;
    return 1;
  }

  pump.wait();

  return 0;
}
