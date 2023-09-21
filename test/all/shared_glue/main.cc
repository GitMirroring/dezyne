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

#include "shared_glue.hh"

#include <dzn/locator.hh>
#include <dzn/pump.hh>
#include <dzn/runtime.hh>

int
main ()
{
  dzn::locator locator;
  dzn::runtime runtime;
  shared_glue sut (locator.set (runtime));

  sut.h.out.world = [&] {};
  sut.w.in.hello = [&] {};
  sut.w.in.bye = sut.w.out.world;

  sut.h.in.hello ();
  sut.w.out.world ();
  sut.h.in.bye ();
}
