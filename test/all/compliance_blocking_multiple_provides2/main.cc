// Dezyne --- Dezyne command line tools

// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include "compliance_blocking_multiple_provides2.hh"

#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int main()
{
  std::cin.ignore (std::numeric_limits<std::streamsize>::max ());

  dzn::locator locator;
  compliance_blocking_multiple_provides2 sut(locator);
  sut.dzn_meta.name = "sut";

  auto f1 = std::async(std::launch::async, [&]{
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    sut.right.in.hello();
  });
  sut.left.in.hello();
  auto f2 = std::async(std::launch::async, [&]{
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    sut.left.in.hello();
  });
  sut.right.in.hello();


  f1.wait();
  f2.wait();
}
