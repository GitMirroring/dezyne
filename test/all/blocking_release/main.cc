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

#include "blocking_release.hh"

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
  blocking_release sut (locator);
  dzn::pump pump;
  locator.set(pump);

  sut.dzn_meta.name = "sut";

  sut.block.dzn_meta.require.name = "block";
  sut.block.dzn_meta.require.port = &sut.block;

  sut.release.dzn_meta.require.name = "release";
  sut.release.dzn_meta.require.port = &sut.release;

  sut.w.dzn_meta.provide.name = "w";
  sut.w.dzn_meta.provide.port = &sut.w;

  sut.w.in.hello = [] () {};

  std::string trace = read ();
  if (0);
  // trace
  else if (trace == "block.hello\nw.hello\nw.return\nrelease.hello\nw.hello\nw.return\nrelease.return\nrelease.hello\nrelease.return\nblock.return")
  {
    pump (sut.block.in.hello);
    pump ([&] {sut.release.in.hello (); sut.release.in.hello ();});
  }
  else if (trace == "block.hello\nw.hello\nw.return\nrelease.hello\nw.hello\nw.return\nrelease.return\nblock.return")
  {
    pump (sut.block.in.hello);
    pump (sut.release.in.hello);
  }
  else if (trace == "block.hello\nw.hello\nw.return\nw.world\nblock.return")
  {
    pump (sut.block.in.hello);
    pump (sut.w.out.world);
  }
  else if (trace == "release.hello\nrelease.return")
    pump (sut.release.in.hello);
  else
  {
    std::clog << "missing trace" << std::endl;
    return 1;
  }

  pump.wait ();

  return 0;
}
