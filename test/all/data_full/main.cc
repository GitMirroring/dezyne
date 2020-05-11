// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2017, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "data_full.hh"

#include <dzn/locator.hh>
#include <dzn/runtime.hh>

#include <algorithm>
#include <cassert>
#include <iostream>

void a0()
{
  std::cout << "port.a0()" << std::endl;
  std::clog << "sut.p.bottom.a0 -> <external>.port.a0" << std::endl;
}

void a(int i)
{
  std::cout << "a(" << i << ")" << std::endl;
  std::clog << "sut.p.bottom.a -> <external>.port.a" << std::endl;
}

void aa(int i, int j)
{
  std::cout << "aa(" << i << "," << j << ")" << std::endl;
  std::clog << "sut.p.bottom.aa -> <external>.port.aa" << std::endl;
  assert(j == 123);
}

void a6(int i0, int i1, int i2, int i3, int i4, int i5)
{
  std::cout << "a6(" << i0 << "," << i1 << "," << i2 << "," << i3 << "," << i4 << "," << i5 << ")" << std::endl;
  std::clog << "sut.p.bottom.a6 -> <external>.port.a6" << std::endl;
  assert(i0 == 0);
  assert(i1 == 1);
  assert(i2 == 2);
  assert(i3 == 3);
  assert(i4 == 4);
  assert(i5 == 5);
}

int main()
{
  std::string str;
  while(std::cin >> str);

  dzn::locator l;
  dzn::runtime rt;
  l.set(rt);

  data_full sut(l);

  sut.dzn_meta.name = "sut";
  sut.port.meta.require.port = "port";

  sut.port.out.a0 = a0;
  sut.port.out.a = a;
  sut.port.out.aa = aa;
  sut.port.out.a6 = a6;

  sut.check_bindings();
  sut.dump_tree();

  assert(Idata_full::Status::Yes == sut.port.in.e0r());
  sut.port.in.e0();
  assert(Idata_full::Status::Yes == sut.port.in.er(123));
  int i = 123;
  sut.port.in.e(i);
  assert(i == 123);
  assert(Idata_full::Status::No == sut.port.in.eer(123,345));

  sut.port.in.eo(i);
  assert(i == 234);

  int j = 0;
  sut.port.in.eoo(i,j);
  assert(i == 123 && j == 456);

  sut.port.in.eio(i,j);
  assert(i == 123 && j == i);

  sut.port.in.eio2(i);
  assert(i == 246);


  assert(Idata_full::Status::Yes == sut.port.in.eor(i));
  assert(i == 234);

  assert(Idata_full::Status::Yes == sut.port.in.eoor(i,j));
  assert(i == 123 && j == 456);

  assert(Idata_full::Status::Yes == sut.port.in.eior(i,j));
  assert(i == 123 && j == i);

  assert(Idata_full::Status::Yes == sut.port.in.eio2r(i));
  assert(i == 246);

  return 0;
}
