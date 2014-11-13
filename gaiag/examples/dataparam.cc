// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "locator.h"
#include "runtime.h"

#include <iostream>

void a0()
{
  std::cout << "a0()" << std::endl;
}

void a(int i)
{
  std::cout << "a(" << i << ")" << std::endl;
}

void aa(int i, int j)
{
  std::cout << "a(" << i << "," << j << ")" << std::endl;
}

void a6(int i0, int i1, int i2,int i3, int i4, int i5)
{
  std::cout << "a6(" << i0 << "," << i1 << "," << i2 << ","<< i3 << "," << i4 << "," << i5 << ")" << std::endl;
}

int main()
{
  dezyne::locator l;
  dezyne::runtime rt;
  l.set(rt);

  dezyne::Dataparam c(l);

  c.port.out.a0 = a0;
  c.port.out.a = a;
  c.port.out.aa = aa;
  c.port.out.a6 = a6;

  assert(dezyne::IDataparam::Status::Yes == c.port.in.e0r());
  c.port.in.e0();
  assert(dezyne::IDataparam::Status::No == c.port.in.er(123));
  c.port.in.e(123);
  assert(dezyne::IDataparam::Status::No == c.port.in.eer(123,345));

  int i = 0;
  c.port.in.eo(i);
  assert(i == 234);

  int j = 0;
  c.port.in.eoo(i,j);
  assert(i == 123 && j == 456);

  c.port.in.eio(i,j);
  assert(i == 123 && j == i);

  c.port.in.eio2(i);
  assert(i == 246);


  assert(dezyne::IDataparam::Status::Yes == c.port.in.eor(i));
  assert(i == 234);

  assert(dezyne::IDataparam::Status::Yes == c.port.in.eoor(i,j));
  assert(i == 123 && j == 456);

  assert(dezyne::IDataparam::Status::Yes == c.port.in.eior(i,j));
  assert(i == 123 && j == i);

  assert(dezyne::IDataparam::Status::Yes == c.port.in.eio2r(i));
  assert(i == 246);
}
