// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "calling_context.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

int main(int argc, char* argv[])
{
  dzn::locator locator;
  dzn::runtime runtime;

  calling_context sut(locator.set(runtime));

  sut.w.in.world = [](int& cc, int i){if(cc == 0){cc = 123;} else {assert(cc == 123); cc = 456;}};

  int cc = 0;

  sut.h.in.hello(cc, 123);

  assert(cc == 456);
}
