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

  dzn::locator loc;
  dzn::runtime rt;
  loc.set(rt);

  std::unique_ptr<dzn::pump> tmp1(new dzn::pump);
  loc.set(*tmp1);

  async_order sut(loc);
  sut.dzn_meta.name = "sut";
  sut.p.meta.requires.port = "p";

  cb1_cancel c(loc);
  c.dzn_meta.name = " ";
  c.p.meta.requires.port = " ";

  std::unique_ptr<dzn::pump> tmp2(std::move(tmp1)); //enter ~pump () first
  dzn::pump& pump = *tmp2;

  int t = 0;
  sut.p.out.cb1 = [t] {std::clog << "sut.p.cb1 -> <external>.p.cb1 [" <<  t << "]" << std::endl;};
  sut.p.out.cb2 = [t] {std::clog << "sut.p.cb2 -> <external>.p.cb2 [" <<  t << "]" << std::endl;};

  if (0);
  else if (trace == "p.e\np.return\np.c\np.return")
    {
      dzn::blocking (pump, [&] {sut.p.in.e ();sut.p.in.c ();});
    }
  else if (trace == "p.e\np.return\np.cb1\np.c\np.return")
    {
      sut.dzn_meta.name = "<external>";
      connect(sut.p, c.r);
      c.p.out.cb1 = [t] {std::clog << "c.p.cb1 -> <external>.p.cb1 [" <<  t << "]" << std::endl;};
      c.p.out.cb2 = [t] {std::clog << "c.p.cb2 -> <external>.p.cb2 [" <<  t << "]" << std::endl;};
      dzn::blocking (pump, [&] {c.p.in.e ();});
    }
  else if (trace == "p.e\np.return\np.cb1\np.cb2")
    {
      dzn::blocking (pump, [&] {sut.p.in.e ();});
    }
  else if (trace == "p.c\np.return")
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
