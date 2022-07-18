// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
// Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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

#include "collateral_blocking_multiple_provides0.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int
main (int argc, char* argv[])
{
  if (argv + argc != std::find_if (argv + 1,
                                   argv + argc,
                                   [] (char const* s)
                                   {return s == std::string ("--debug");}))
    dzn::debug.rdbuf (std::clog.rdbuf ());

  dzn::locator loc;
  dzn::runtime rt;
  loc.set (rt);
  collateral_blocking_multiple_provides0 sut (loc);
  sut.dzn_meta.name = "sut";
  sut.r.meta.provide.name = "r";

  sut.r.in.hello = [&]
  {
    dzn::trace(std::clog, sut.r.meta, "hello");
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    sut.r.out.world();
    dzn::trace_out(std::clog, sut.r.meta, "return");
  };

  std::thread t([&]{
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    sut.right.in.hello ();
  });

  sut.left.in.hello ();

  t.join();

  return 0;
}
