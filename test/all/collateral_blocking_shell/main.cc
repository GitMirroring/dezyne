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

#include "collateral_blocking_shell.hh"

#include <limits>
#include <thread>

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

int
main ()
{
  std::cin.ignore (std::numeric_limits<std::streamsize>::max ());

  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);
  collateral_blocking_shell sut (locator);
  sut.dzn_meta.name = "sut";
  sut.w0.dzn_meta.provide.name = "w0";
  sut.w1.dzn_meta.provide.name = "w1";

  bool cruel = false;
  sut.w0.in.hello = [&]
  {
  };
  sut.w1.in.hello = [&]
  {
    if (cruel)
      {
        std::thread ([&]
        {
          sut.h.in.cruel ();
        }).detach();
      }

    std::thread ([&]
    {
      std::this_thread::sleep_for (std::chrono::milliseconds (50));
      sut.w0.out.world ();
      sut.w1.out.world ();
    }).detach();
  };

  std::clog << "hello happy\n";
  sut.h.in.hello ();
  cruel = true;
  std::clog << "hello cruel\n";
  sut.h.in.hello ();

  return 0;
}
