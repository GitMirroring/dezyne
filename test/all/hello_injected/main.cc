// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2021, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Henk Katerberg <hank@mudball.nl>
// Copyright © 2022 Rutger van Beusekom <rutger@dezyne.org>
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

#include "hello_injected.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

#include <iostream>

int
main ()
{
  std::string str;
  while (std::cin >> str);

  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);

  hello_injected sut (locator);
  sut.dzn_meta.name = "sut";
  sut.h.dzn_meta.require.name = "h";
  sut.h.dzn_meta.require.component = 0;
  sut.h.out.world = [] () {};

  dzn::check_bindings (sut);
  dzn::dump_tree (sut);

  sut.h.in.hello ();
}
