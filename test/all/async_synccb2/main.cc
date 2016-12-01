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

#include "async_synccb2.hh"

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

  dzn::locator loc;
  dzn::runtime rt;
  loc.set(rt);
  dzn::pump pump;
  loc.set(pump);

  async_synccb2 sut(loc);

  sut.dzn_meta.name = "sut";
  sut.p.meta.requires.port = "p";
  sut.r.meta.provides.port = "r";
  int t = 0;

  sut.p.out.cb = [t] {std::clog << "sut.p.cb -> <external>.p.cb [" <<  t << "]" << std::endl;};
  sut.r.in.e = [t] {std::clog << "sut.r.e -> <external>.r.e [" <<  t << "]" << std::endl;
                    std::clog << "sut.r.return -> <external>.r.return" << std::endl;};
  sut.r.in.c = [t] {std::clog << "sut.r.c -> <external>.r.c [" <<  t << "]" << std::endl;
                    std::clog << "sut.r.return -> <external>.r.return" << std::endl;};

  if (0);
  else if (trace == "p.e\nr.e\nr.return\np.return\np.c\nr.c\nr.return\np.return")
    {
      dzn::blocking (pump, [&] {sut.p.in.e ();});
      dzn::blocking (pump, [&] {sut.p.in.c ();});
    }
  else if (trace == "p.e\nr.e\nr.return\np.return\nr.cb1\nr.cb2\np.c\nr.c\nr.return\np.return")
    {
      dzn::blocking (pump, [&] {sut.p.in.e ();sut.r.out.cb1 ();sut.r.out.cb2 ();sut.p.in.c ();});
    }
  else if (trace == "p.e\nr.e\nr.return\np.return\nr.cb1\nr.cb2\np.cb")
    {
      dzn::blocking (pump, [&] {sut.p.in.e ();sut.r.out.cb1 ();sut.r.out.cb2 ();});
    }
  else if (trace == "p.c\nr.c\nr.return\np.return")
    {
      dzn::blocking (pump, [&] {sut.p.in.c ();});
    }
  else
    {
      std::clog << "error: invalid trace: " << trace << std::endl;
      return 1;
    }
  return 0;
}
