// Dezyne --- Dezyne command line tools
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

#include "async_order.hh"
#include "cb1_cancel.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>
#include <dzn/pump.hh>

#include <algorithm>
#include <cassert>
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

  struct C {
    dzn::locator loc;
    dzn::runtime rt;
    async_order sut;
    cb1_cancel c;
    dzn::pump pump;

    C()
    : sut(loc.set(rt).set(pump))
    , c(loc.set(rt).set(pump))
    , pump()
    {}
  };
  C c;
  c.sut.dzn_meta.name = "sut";
  c.sut.p.meta.requires.port = "p";

  c.c.dzn_meta.name = " ";
  c.c.p.meta.requires.port = " ";

  int t = 0;
  c.sut.p.out.cb1 = [t] {std::clog << "sut.p.cb1 -> <external>.p.cb1 [" <<  t << "]" << std::endl;};
  c.sut.p.out.cb2 = [t] {std::clog << "sut.p.cb2 -> <external>.p.cb2 [" <<  t << "]" << std::endl;};

  if (0);
  else if (trace == "p.e\np.return\np.c\np.return")
    {
      dzn::blocking (c.pump, [&] {c.sut.p.in.e ();c.sut.p.in.c ();});
    }
  else if (trace == "p.e\np.return\np.cb1\np.c\np.return")
    {
      c.sut.dzn_meta.name = "<external>";
      connect(c.sut.p, c.c.r);
      c.c.p.out.cb1 = [t] {std::clog << "c.p.cb1 -> <external>.p.cb1 [" <<  t << "]" << std::endl;};
      c.c.p.out.cb2 = [t] {std::clog << "c.p.cb2 -> <external>.p.cb2 [" <<  t << "]" << std::endl;};
      dzn::blocking (c.pump, [&] {c.c.p.in.e ();});
    }
  else if (trace == "p.e\np.return\np.cb1\np.cb2")
    {
      dzn::blocking (c.pump, [&] {c.sut.p.in.e ();});
    }
  else if (trace == "p.c\np.return")
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
