// Dezyne --- Dezyne command line tools

// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "collateral_blocking_shell3.hh"

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
  collateral_blocking_shell3 sut (loc);
  sut.dzn_meta.name = "sut";
  sut.w0.meta.require.port = "w0";
  sut.w1.meta.require.port = "w1";

  sut.h.out.bye = [&]
  {
    std::clog << "<external>.h.bye <- sut.top.h.bye" << std::endl;
  };
  sut.w0.in.hello = [&]
  {
    std::clog << "sut.blocked.w0.hello -> <external>.w0.hello\n";
  };
  sut.w1.in.hello = [&]
  {
    std::clog << "sut.blocked.w1.hello -> <external>.w1.hello\n";

    std::thread ([&]
    {
      std::this_thread::sleep_for (std::chrono::milliseconds (2000));
      std::clog << "world0\n";
      sut.w0.out.world ();
      std::this_thread::sleep_for (std::chrono::milliseconds (2000));
      std::clog << "world1\n";
      sut.w1.out.world ();
    }).detach();
  };
  sut.w2.in.hello = [&] {
    std::clog << "sut.top.w1.hello -> <external>.w2.hello\n";
    sut.w2.out.world();
  };

  sut.h.in.hello ();

  return 0;
}
