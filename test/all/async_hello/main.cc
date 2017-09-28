// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "async_hello.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <algorithm>
#include <cassert>
#include <future>
#include <iostream>

namespace dzn {
  template <typename L, typename = typename std::enable_if<std::is_void<typename std::result_of<L()>::type>::value>::type>
  void blocking(dzn::pump& pump, L&& l)
  {
    std::promise<void> p;
    pump([&]{l(); p.set_value();});
    return p.get_future().get();
  }
  template <typename L, typename = typename std::enable_if<!std::is_void<typename std::result_of<L()>::type>::value>::type>
  auto blocking(dzn::pump& pump, L&& l) -> decltype(l())
  {
    std::promise<decltype(l())> p;
    pump([&]{p.set_value(l());});
    return p.get_future().get();
  }
}

int main()
{
  std::string str;
  while(std::cin >> str);

  struct C
  {
    dzn::locator loc;
    dzn::runtime rt;
    async_hello sut;
    dzn::pump pump;

    C()
    : sut(loc.set(rt).set(pump))
    , pump()
    {
      sut.dzn_meta.name = "sut";
      sut.p.meta.requires.port = "p";
    }
  };
  C c;

  c.sut.p.out.a = [] (int t) {std::clog << "p.a -> <external>.p.a [" <<  t << "]" << std::endl;};

  dzn::blocking (c.pump, [&] {c.sut.p.in.e (0);});
  return 0;
}
