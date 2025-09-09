// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016, 2018 Rutger van Beusekom <rutger@dezyne.org>
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

// -*-java-*-
using System;
using System.Diagnostics;

class main {

  static void assert(bool b) {
    if (!b) {
      throw new dzn.RuntimeException("assertion failure");
    }
  }

  static void a0() {
    System.Console.WriteLine("a0()");
    System.Console.Error.WriteLine("sut.p.bottom.a0 -> <external>.port.a0");
  }

  static void a(int i) {
    System.Console.WriteLine("a(" + i + ")");
    System.Console.Error.WriteLine("sut.p.bottom.a -> <external>.port.a");
  }

  static void aa(int i, int j) {
    System.Console.WriteLine("aa(" + i + "," + j + ")");
    System.Console.Error.WriteLine("sut.p.bottom.aa -> <external>.port.aa");
    assert(j == 123);
  }

  static void a6(int i0, int i1, int i2, int i3, int i4, int i5) {
    System.Console.WriteLine("a6(" + i0 + "," + i1 + "," + i2 + "," + i3 + "," + i4 + "," + i5 + ")");
    System.Console.Error.WriteLine("sut.p.bottom.a6 -> <external>.port.a6");
    assert(i0 == 0);
    assert(i1 == 1);
    assert(i2 == 2);
    assert(i3 == 3);
    assert(i4 == 4);
    assert(i5 == 5);
  }

  public static void Main(String[] args) {
    dzn.Locator locator = new dzn.Locator();
    dzn.Runtime runtime = new dzn.Runtime();
    data_full sut = new data_full(locator.set(runtime), "sut");
    sut.port.meta.require.name = "port";
    sut.port.meta.require.component = null;

    sut.port.out_port.a0 = () => {a0();};
    sut.port.out_port.a = (int p) => {a(p);};
    sut.port.out_port.aa = (int p0, int p1) => {aa(p0, p1);};
    sut.port.out_port.a6 = (int p0, int p1, int p2, int p3, int p4, int p5) => {a6(p0, p1, p2, p3, p4, p5);};

    assert(Idata_full.Status.Yes == sut.port.in_port.e0r());
    sut.port.in_port.e0();
    assert(Idata_full.Status.Yes == sut.port.in_port.er(123));
    sut.port.in_port.e(123);
    assert(Idata_full.Status.No == sut.port.in_port.eer(123,345));

    int i = 0;
    sut.port.in_port.eo(out i);
    assert(i == 234);

    int j = 0;
    sut.port.in_port.eoo(out i,out j);
    assert(i == 123 && j == 456);

    sut.port.in_port.eio(i,out j);
    assert(i == 123 && j == i);

    sut.port.in_port.eio2(ref i);
    assert(i == 246);


    assert(Idata_full.Status.Yes == sut.port.in_port.eor(out i));
    assert(i == 234);

    assert(Idata_full.Status.Yes == sut.port.in_port.eoor(out i,out j));
    assert(i == 123 && j == 456);

    assert(Idata_full.Status.Yes == sut.port.in_port.eior(i,out j));
    assert(i == 123 && j == i);

    assert(Idata_full.Status.Yes == sut.port.in_port.eio2r(ref i));
    assert(i == 246);
  }
}
