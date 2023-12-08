// Dezyne --- Dezyne command line tools
//
// Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
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

#include "hello_mock.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

int
main ()
{
  bool cruel = false;
  bool world = false;
  bool hello = false;

  dzn::locator locator;
  dzn::runtime runtime;

  hello_mock sut (locator.set (runtime));

  sut.w.in.hello = [&]{hello = true; sut.w.out.cruel ();};
  sut.h.out.cruel = [&]{cruel = true;};
  sut.h.out.world = [&]{world = true;};

  sut.h.in.hello ();

  assert (hello);
  assert (cruel);

  sut.w.out.world ();

  assert (world);
}
