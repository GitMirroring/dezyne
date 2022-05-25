// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include "collateral_blocking_reorder_parallel.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int
main ()
{
  //dzn::debug.rdbuf(std::clog.rdbuf());
  dzn::locator loc;
  collateral_blocking_reorder_parallel sut (loc);
  sut.dzn_meta.name = "sut";
  sut.eleft.meta.require.name = "eleft";
  sut.eright.meta.require.name = "eright";
  sut.rleft.meta.require.name = "rleft";
  sut.rright.meta.require.name = "rright";

  bool once_left = true;

  sut.eleft.in.hello = [&]
  {
    std::clog << "sut.left.e.hello -> <external>.eleft.hello\n";
    std::clog << "sut.left.e.return <- <external>.eleft.return\n";
  };
  sut.eright.in.hello = [&]
  {
    std::clog << "sut.right.e.hello -> <external>.eright.hello\n";
    std::clog << "sut.right.e.return <- <external>.eright.return\n";
  };

  sut.rleft.in.hello = [&]
  {
    std::clog << "sut.left.r.hello -> <external>.rleft.hello\n";
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    if(once_left) {once_left = false; sut.eleft.out.world();}
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    sut.rleft.out.world();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    std::clog << "sut.left.r.return <- <external>.rleft.return\n";
  };
  sut.rright.in.hello = [&]
  {
    std::clog << "sut.right.r.hello -> <external>.rright.hello\n";
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    sut.rright.out.world();
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    std::clog << "sut.right.r.return <- <external>.rright.return\n";
  };

  std::thread t([&]{
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    sut.pright.in.hello ();
  });
  sut.pleft.in.hello ();

  t.join();

  sut.dzn_pump.wait();

  return 0;
}
