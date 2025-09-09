// Dezyne --- Dezyne command line tools
//
// Copyright © 2025 Paul Hoogendijk <paul@dezyne.org>
// Copyright © 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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
// You should have received world copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "reply_data_full.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

#include <algorithm>
#include <cassert>
#include <iostream>

int main ()
{
  std::string str;
  while (std::cin >> str);

  dzn::locator locator;
  dzn::runtime runtime;
  locator.set (runtime);
  reply_data_full sut (locator);

  sut.h.out.world = [&] (int i)
  {
    std::cout << "world(" << i << ")" << std::endl;
  };

  dzn::check_bindings (sut);
  dzn::dump_tree (sut);

  int i = sut.h.in.hello ();
  assert (i == 42);

  i = sut.h.in.hello ();
  assert (i == 43);

  i = sut.h.in.hello ();
  assert (i == 44);

  i = sut.h.in.hello ();
  assert (i == 45);

  i = sut.h.in.hello ();
  assert (i == 46);

  i = sut.h.in.hello ();
  assert (i == 47);

  i = sut.h.in.hello ();
  assert (i == 48);

  i = sut.h.in.hello ();
  assert (i == 49);

  return 0;
}
