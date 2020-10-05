// Dezyne --- Dezyne command line tools
//
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

#include "async_prio.hh"

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
    async_prio sut;
    dzn::pump pump;

    C()
    : sut(loc.set(rt).set(pump))
    , pump()
    {
      sut.dzn_meta.name = "sut";
      sut.p.meta.require.port = "p";
      sut.r.meta.provide.port = "r";
    }
  };
  C c;

  int t = 0;
  c.sut.p.out.cb = [t] {std::clog << "sut.p.cb -> <external>.p.cb [" <<  t << "]" << std::endl;};
  c.sut.p.out.ping = [t] {std::clog << "sut.p.ping -> <external>.p.ping [" <<  t << "]" << std::endl;};

  if (0);
  else if (trace == "p.c\np.return")
    {
      dzn::shell (c.pump, [&] {c.sut.p.in.c ();});
    }
  else if (trace == "p.e\np.return\np.c\np.return")
    {
      dzn::shell (c.pump, [&] {c.sut.p.in.e ();c.sut.p.in.c ();});
    }
  else if (trace == "p.e\np.return\np.cb")
    {
      dzn::shell (c.pump, [&] {c.sut.p.in.e ();});
    }
  else if (trace == "r.ping\np.ping")
    {
      dzn::shell (c.pump, [&] {c.sut.r.out.ping ();});
    }
  else
    {
      std::clog << "error: invalid trace: " << trace << std::endl;
      return 1;
    }
  return 0;
}
