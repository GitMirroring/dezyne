// Dezyne --- Dezyne command line tools
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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
  }

  static void a(int i) {
    System.Console.WriteLine("a(" + i + ")");
  }

  static void aa(int i, int j) {
    System.Console.WriteLine("aa(" + i + "," + j + ")");
    assert(j == 123);
  }

  static void a6(int i0, int i1, int i2, int i3, int i4, int i5) {
    System.Console.WriteLine("a6(" + i0 + "," + i1 + "," + i2 + "," + i3 + "," + i4 + "," + i5 + ")");
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
    Dataparam sut = new Dataparam(locator.set(runtime), "sut");
    sut.port.dzn_meta.requires.name = "port";
    sut.port.dzn_meta.requires.component = null;

    sut.port.outport.a0 = () => {a0();};
    sut.port.outport.a = (int p) => {a(p);};
    sut.port.outport.aa = (int p0, int p1) => {aa(p0, p1);};
    sut.port.outport.a6 = (int p0, int p1, int p2, int p3, int p4, int p5) => {a6(p0, p1, p2, p3, p4, p5);};

    assert(IDataparam.Status.Yes == sut.port.inport.e0r());
    sut.port.inport.e0();
    assert(IDataparam.Status.Yes == sut.port.inport.er(123));
    sut.port.inport.e(123);
    assert(IDataparam.Status.No == sut.port.inport.eer(123,345));

    dzn.V<int> i = new dzn.V<int>(0);
    sut.port.inport.eo(i);
    assert(i.v == 234);

    dzn.V<int> j = new dzn.V<int>(0);
    sut.port.inport.eoo(i,j);
    assert(i.v == 123 && j.v == 456);

    sut.port.inport.eio(i.v,j);
    assert(i.v == 123 && j.v == i.v);

    sut.port.inport.eio2(i);
    assert(i.v == 246);


    assert(IDataparam.Status.Yes == sut.port.inport.eor(i));
    assert(i.v == 234);

    assert(IDataparam.Status.Yes == sut.port.inport.eoor(i,j));
    assert(i.v == 123 && j.v == 456);

    assert(IDataparam.Status.Yes == sut.port.inport.eior(i.v,j));
    assert(i.v == 123 && j.v == i.v);

    assert(IDataparam.Status.Yes == sut.port.inport.eio2r(i));
    assert(i.v == 246);
  }
}
