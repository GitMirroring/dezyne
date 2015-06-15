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

// -*-java-*-
using System;
using System.Diagnostics;

class main {

  static void assert(bool b) {
    if (!b) {
      throw new RuntimeException("assertion failure");
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
    Locator locator = new Locator();
    Runtime runtime = new Runtime();
    Datasystem d = new Datasystem(locator.set(runtime), "d");
    d.port.outport.name = "port";
    d.port.outport.self = null;

    d.port.outport.a0 = () => {a0();};
    d.port.outport.a = (int p) => {a(p);};
    d.port.outport.aa = (int p0, int p1) => {aa(p0, p1);};
    d.port.outport.a6 = (int p0, int p1, int p2, int p3, int p4, int p5) => {a6(p0, p1, p2, p3, p4, p5);};

    assert(IDataparam.Status.Yes == d.port.inport.e0r());
    d.port.inport.e0();
    assert(IDataparam.Status.Yes == d.port.inport.er(123));
    d.port.inport.e(123);
    assert(IDataparam.Status.No == d.port.inport.eer(123,345));

    V<int> i = new V<int>(0);
    d.port.inport.eo(i);
    assert(i.v == 234);

    V<int> j = new V<int>(0);
    d.port.inport.eoo(i,j);
    assert(i.v == 123 && j.v == 456);

    d.port.inport.eio(i.v,j);
    assert(i.v == 123 && j.v == i.v);

    d.port.inport.eio2(i);
    assert(i.v == 246);


    assert(IDataparam.Status.Yes == d.port.inport.eor(i));
    assert(i.v == 234);

    assert(IDataparam.Status.Yes == d.port.inport.eoor(i,j));
    assert(i.v == 123 && j.v == 456);

    assert(IDataparam.Status.Yes == d.port.inport.eior(i.v,j));
    assert(i.v == 123 && j.v == i.v);

    assert(IDataparam.Status.Yes == d.port.inport.eio2r(i));
    assert(i.v == 246);
  }
}
