// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include "double_collateral_blocking_shell.hh"

#include <limits>
#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

int main()
{
  std::cin.ignore (std::numeric_limits<std::streamsize>::max ());

  //dzn::debug.rdbuf(std::clog.rdbuf());
  dzn::locator locator;
  dzn::runtime runtime;
  double_collateral_blocking_shell sut(locator.set(runtime));
  sut.dzn_meta.name = "sut";
  sut.la.meta.require.name = "la";
  sut.la.meta.require.port = &sut.la;
  sut.ra.meta.require.name = "ra";
  sut.ra.meta.require.port = &sut.ra;

  bool toggle = true;
  sut.la.in.ping = [&]{
    std::clog << "sut.lbp.async.ping -> <external>.la.ping" << std::endl;
    std::this_thread::sleep_for(std::chrono::milliseconds(toggle ? 200 : 100));
    sut.la.out.pong();
    std::clog << "sut.lbp.async.return <- <external>.la.return" << std::endl;
  };
  sut.ra.in.ping = [&]{
    std::clog << "sut.rbp.async.ping -> <external>.ra.ping" << std::endl;
    std::this_thread::sleep_for(std::chrono::milliseconds(toggle ? 200 : 100));
    sut.ra.out.pong();
    std::clog << "sut.rbp.async.return <- <external>.ra.return" << std::endl;
  };

  for(size_t i = 0; i < 2; ++i) {
    auto f1 = std::async(std::launch::async, [&]{
      sut.right.in.hello();});
    auto f2 = std::async(std::launch::async, [&]{
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
      sut.left.in.hello();});
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    sut.left.in.hello();

    f1.wait();
    f2.wait();

    toggle = !toggle;
  }
}
