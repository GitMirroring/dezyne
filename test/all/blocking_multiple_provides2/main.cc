// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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

#include "blocking_multiple_provides2.hh"

#include <limits>
#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int main ()
{
  std::cin.ignore (std::numeric_limits<std::streamsize>::max ());

  dzn::locator locator;
  dzn::runtime runtime;
  blocking_multiple_provides2 sut (locator.set (runtime));
  dzn::pump pump;
  locator.set(pump);

  sut.dzn_meta.name = "sut";
  sut.w_left.meta.provide.name = "w_left";
  sut.w_right.meta.provide.name = "w_right";

  sut.w_left.in.hello = [&]
  {
    std::thread ([&]{
      std::this_thread::sleep_for (std::chrono::milliseconds (100));
      sut.w_left.out.world ();
    }).detach();
  };

  sut.w_right.in.hello = [&]
  {
    std::thread ([&]{
      std::this_thread::sleep_for (std::chrono::milliseconds (150));
      sut.w_right.out.world ();
    }).detach();
  };

  std::thread([&]{
    sut.h_left.in.hello ();
  }).detach();
  std::this_thread::sleep_for (std::chrono::milliseconds (50));
  sut.h_right.in.hello ();
}
