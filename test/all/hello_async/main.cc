// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "hello_async.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <algorithm>
#include <cassert>
#include <future>
#include <iostream>

int main()
{
  std::string str;
  while(std::cin >> str);

  struct C
  {
    dzn::locator loc;
    dzn::runtime rt;
    hello_async sut;
    dzn::pump pump;

    C()
    : sut(loc.set(rt).set(pump))
    , pump()
    {
      sut.dzn_meta.name = "sut";
      sut.p.meta.require.port = "p";
    }
  };
  C c;

  c.sut.p.out.a = [] (int t) {std::clog << "p.a -> <external>.p.a [" <<  t << "]" << std::endl;};

  dzn::shell (c.pump, [&] {c.sut.p.in.e (0);});
  return 0;
}
