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

#include "collateral_blocking_shell2.hh"

#include <limits>
#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int
main ()
{
  std::cin.ignore (std::numeric_limits<std::streamsize>::max ());

  dzn::locator loc;
  dzn::runtime rt;
  loc.set (rt);
  collateral_blocking_shell2 sut (loc);
  sut.dzn_meta.name = "sut";
  sut.w.meta.require.port = "w";

  std::future<void> f1, f2;
  sut.w.in.hello = [&]
  {
    std::clog << "sut.blocked.w.hello -> <external>.w.hello\n";
    f1 = std::async (std::launch::async, [&]
    {
      std::this_thread::sleep_for (std::chrono::milliseconds (50));
      std::clog << "cruel\n";
      sut.h.in.cruel ();
    });
    f2 = std::async (std::launch::async, [&]
    {
      std::this_thread::sleep_for (std::chrono::milliseconds (100));
      std::clog << "world\n";
      sut.w.out.world ();
    });
  };

  sut.w.in.cruel = [&]{
    sut.w.out.bye();
  };

  sut.h.in.hello ();

  f1.wait();
  f2.wait();

  return 0;
}
