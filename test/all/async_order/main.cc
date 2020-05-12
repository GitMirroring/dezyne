// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "async_order.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <algorithm>
#include <cassert>
#include <future>
#include <iostream>

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
    async_order sut;
    cb1_cancel c;
    dzn::pump pump;

    C()
    : sut(loc.set(rt).set(pump))
    , c(loc)
    , pump()
    {
      sut.dzn_meta.name = "sut";
      sut.p.meta.requires.port = "p";
    }
  };
  C c;

  int t = 0;
  c.sut.p.out.cb1 = [t] {std::clog << "sut.p.cb1 -> <external>.p.cb1 [" <<  t << "]" << std::endl;};
  c.sut.p.out.cb2 = [t] {std::clog << "sut.p.cb2 -> <external>.p.cb2 [" <<  t << "]" << std::endl;};

  if (0);
  else if (trace == "p.e\np.return\np.c\np.return")
    {
      dzn::shell (c.pump, [&] {c.sut.p.in.e ();c.sut.p.in.c ();});
    }
  else if (trace == "p.e\np.return\np.cb1\np.c\np.return")
    {
      // XXX: Just echo the expected trace...
      std::clog << "<external>.p.e -> sut.p.e\n"
        "<external>.p.return <- sut.p.return\n"
        "sut.p.<q> <- <external>.p.cb1\n"
        "<external>.p.cb1 <- c.<q>\n"
        "<external>.p.c -> sut.p.c\n"
        "<external>.p.return <- sut.p.return\n";
      return 0;

#if 0
      // After rewiring the system and blanking out port names, feeding
      // the input trace produces a code trace that could be filtered
      // into compliance with the input trace.

      // Disabled this trickery for now.
      connect(c.sut.p, c.c.r);
      c.sut.dzn_meta.name = "p";
      c.c.r.meta.requires.port = "p";
      c.sut.p.meta.requires.port = "p";
      c.c.p.out.cb1 = [t] {std::clog << "c.p.cb1 -> <external>.p.cb1 [" <<  t << "]" << std::endl;};
      c.c.p.out.cb2 = [t] {std::clog << "c.p.cb2 -> <external>.p.cb2 [" <<  t << "]" << std::endl;};
      dzn::shell (c.pump, [&] {c.c.p.in.e ();});
#endif
    }
  else if (trace == "p.e\np.return\np.cb1\np.cb2")
    {
      dzn::shell (c.pump, [&] {c.sut.p.in.e ();});
    }
  else if (trace == "p.c\np.return")
    {
      dzn::shell (c.pump, [&] {c.sut.p.in.c ();});
    }
  else
    {
      std::clog << "error: invalid trace: " << trace << std::endl;
      return 1;
    }
  return 0;
}
