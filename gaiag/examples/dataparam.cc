// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Gaiag.
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#include "Datasystem.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

#include <algorithm>
#include <iostream>

void a0()
{
  std::clog << "a0()" << std::endl;
}

void a(int i)
{
  std::clog << "a(" << i << ")" << std::endl;
}

void aa(int i, int j)
{
  std::clog << "aa(" << i << "," << j << ")" << std::endl;
  assert(j == 123);
}

void a6(int i0, int i1, int i2, int i3, int i4, int i5)
{
  std::clog << "a6(" << i0 << "," << i1 << "," << i2 << "," << i3 << "," << i4 << "," << i5 << ")" << std::endl;
  assert(i0 == 0);
  assert(i1 == 1);
  assert(i2 == 2);
  assert(i3 == 3);
  assert(i4 == 4);
  assert(i5 == 5);
}

int main()
{
  dzn::locator l;
  dzn::runtime rt;
  l.set(rt);

  Datasystem d(l);

  d.dzn_meta.name = "d";
  d.port.meta.requires = {"port",&d};

  d.port.out.a0 = a0;
  d.port.out.a = a;
  d.port.out.aa = aa;
  d.port.out.a6 = a6;

  d.check_bindings();
  d.dump_tree();

  assert(IDataparam::Status::Yes == d.port.in.e0r());
  d.port.in.e0();
  assert(IDataparam::Status::Yes == d.port.in.er(123));
  d.port.in.e(123);
  assert(IDataparam::Status::No == d.port.in.eer(123,345));

  int i = 0;
  d.port.in.eo(i);
  assert(i == 234);

  int j = 0;
  d.port.in.eoo(i,j);
  assert(i == 123 && j == 456);

  d.port.in.eio(i,j);
  assert(i == 123 && j == i);

  d.port.in.eio2(i);
  assert(i == 246);


  assert(IDataparam::Status::Yes == d.port.in.eor(i));
  assert(i == 234);

  assert(IDataparam::Status::Yes == d.port.in.eoor(i,j));
  assert(i == 123 && j == 456);

  assert(IDataparam::Status::Yes == d.port.in.eior(i,j));
  assert(i == 123 && j == i);

  assert(IDataparam::Status::Yes == d.port.in.eio2r(i));
  assert(i == 246);
}
