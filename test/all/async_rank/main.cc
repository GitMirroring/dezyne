// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "async_rank.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <future>
#include <iostream>
#include <limits>

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
  std::cin.ignore(std::numeric_limits<std::streamsize>::max());

  struct C
  {
    dzn::locator loc;
    dzn::runtime rt;
    async_rank sut;
    dzn::pump pump;

    C()
    : sut(loc.set(rt).set(pump))
    , pump()
    {
      sut.dzn_meta.name = "sut";
      sut.p.meta.requires.port = "p";
      sut.r.meta.provides.port = "r";
    }
  };
  C c;

  dzn::apply(&c.sut.dzn_meta, [](const dzn::meta* m){std::clog << m->parent << " " << m << " " << m->name << " " << m->rank << std::endl;});

  c.sut.p.out.f = [] {std::clog << "sut.p.f -> <external>.p.f" << std::endl;};
  c.sut.p.out.g = [] {std::clog << "sut.p.g -> <external>.p.g" << std::endl;};

  c.sut.r.in.e = [] {
    std::clog << "sut.r.e -> <external>.r.e" << std::endl;
    std::clog << "<external>.r.return -> sut.r.return" << std::endl;
  };

  dzn::blocking(c.pump, c.sut.p.in.e);
  dzn::blocking(c.pump, c.sut.r.out.f);
  dzn::blocking(c.pump, c.sut.r.out.g);
}
