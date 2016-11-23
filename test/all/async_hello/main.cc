// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "async_hello.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <algorithm>
#include <cassert>
#include <iostream>

int main()
{
  std::string str;
  while(std::cin >> str);

  dzn::locator loc;
  dzn::runtime rt;
  loc.set(rt);
  dzn::pump pump;
  loc.set(pump);

  async_hello sut(loc);

  sut.dzn_meta.name = "sut";
  sut.p.meta.requires.port = "p";
  sut.p.out.a = [] (int t) {std::clog << "p.a -> <external>.p.a [" <<  t << "]" << std::endl;};

  dzn::blocking (pump, [&] {sut.p.in.e (0);});
  return 0;
}
