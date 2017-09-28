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

#include "async_synccb2.hh"

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

std::string
read ()
{
  std::string str;
  {
    std::string line;
    while(std::cin >> line) str += (str.empty () ? "" : "\n") + line;
  }
  return str;
}

int main()
{
  std::string trace = read ();

  struct C
  {
    dzn::locator loc;
    dzn::runtime rt;
    async_synccb2 sut;
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

  int t = 0;

  c.sut.p.out.cb = [t] {std::clog << "sut.p.cb -> <external>.p.cb [" <<  t << "]" << std::endl;};
  c.sut.r.in.e = [t] {std::clog << "sut.r.e -> <external>.r.e [" <<  t << "]" << std::endl;
                      std::clog << "sut.r.return -> <external>.r.return" << std::endl;};
  c.sut.r.in.c = [t] {std::clog << "sut.r.c -> <external>.r.c [" <<  t << "]" << std::endl;
                      std::clog << "sut.r.return -> <external>.r.return" << std::endl;};

  if (0);
  else if (trace == "p.e\nr.e\nr.return\np.return\np.c\nr.c\nr.return\np.return")
    {
      dzn::blocking (c.pump, [&] {c.sut.p.in.e ();});
      dzn::blocking (c.pump, [&] {c.sut.p.in.c ();});
    }
  else if (trace == "p.e\nr.e\nr.return\np.return\nr.cb1\nr.cb2\np.c\nr.c\nr.return\np.return")
    {
      dzn::blocking (c.pump, [&] {c.sut.p.in.e ();c.sut.r.out.cb1 ();c.sut.r.out.cb2 ();c.sut.p.in.c ();});
    }
  else if (trace == "p.e\nr.e\nr.return\np.return\nr.cb1\nr.cb2\np.cb")
    {
      dzn::blocking (c.pump, [&] {c.sut.p.in.e ();c.sut.r.out.cb1 ();c.sut.r.out.cb2 ();});
    }
  else if (trace == "p.c\nr.c\nr.return\np.return")
    {
      dzn::blocking (c.pump, [&] {c.sut.p.in.c ();});
    }
  else
    {
      std::clog << "error: invalid trace: " << trace << std::endl;
      return 1;
    }
  return 0;
}
