// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "shadow.hh"

#include "locator.hh"
#include "runtime.hh"

#include <algorithm>
#include <cassert>
#include <iostream>

int main()
{
  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);

  shadow sut(l);
  dezyne::pump pump;
  l.set(pump);

  sut.dzn_meta.name = "sut";
  sut.p.meta.requires.port = "p";
  pump.and_wait([&]{sut.p.in.e(1, 2);});
  int r;
  pump.and_wait([&]{sut.p.in.f(r);});
  assert(r==1);
  std::clog << "r=" << r << std::endl;
  pump.and_wait([&]{sut.p.in.e(3, 4);});
  pump.and_wait([&]{sut.p.in.b(r);});
  std::clog << "r=" << r << std::endl;
  assert(r==3);
}
