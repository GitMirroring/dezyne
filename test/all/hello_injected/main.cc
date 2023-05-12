// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

int main()
{
  std::string str;
  while(std::cin >> str);

  dzn::locator l;
  dzn::runtime rt;
  l.set(rt);

  hello_injected sut(l);
  sut.dzn_meta.name = "sut";
  sut.t.meta.require.name = "t";
  sut.t.meta.require.component = 0;
  sut.t.out.f = [] () {};

  dzn::check_bindings(sut);
  dzn::dump_tree(sut);

  sut.t.in.e();
}
