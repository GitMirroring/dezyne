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

class main {

  static void a0() {
    System.err.println("a0()");
  }

  static void a(int i) {
    System.err.println("a(" + i + ")");
  }

  static void aa(int i, int j) {
    System.err.println("aa(" + i + "," + j + ")");
    assert(j == 123);
  }

  static void a6(int i0, int i1, int i2, int i3, int i4, int i5) {
    System.err.println("a6(" + i0 + "," + i1 + "," + i2 + "," + i3 + "," + i4 + "," + i5 + ")");
    assert(i0 == 0);
    assert(i1 == 1);
    assert(i2 == 2);
    assert(i3 == 3);
    assert(i4 == 4);
    assert(i5 == 5);
  }

  public static void main(String[] args) {
    Locator locator = new Locator();
    Runtime runtime = new Runtime();
    Datasystem d = new Datasystem(locator.set(runtime), "d");
    d.port.out.name = "port";
    d.port.out.self = null;

    d.port.out.a0 = () -> {a0();};
    d.port.out.a = (Integer p) -> {a(p);};
    d.port.out.aa = (Integer p0, Integer p1) -> {aa(p0, p1);};
    d.port.out.a6 = (Integer p0, Integer p1, Integer p2, Integer p3, Integer p4, Integer p5) -> {a6(p0, p1, p2, p3, p4, p5);};

    assert(IDataparam.Status.Yes == d.port.in.e0r.action());
    d.port.in.e0.action();
    assert(IDataparam.Status.Yes == d.port.in.er.action(123));
    d.port.in.e.action(123);
    assert(IDataparam.Status.No == d.port.in.eer.action(123,345));

    V<Integer> i = new V<Integer>(0);
    d.port.in.eo.action(i);
    assert(i.v == 234);

    V<Integer> j = new V<Integer>(0);
    d.port.in.eoo.action(i,j);
    assert(i.v == 123 && j.v == 456);

    d.port.in.eio.action(i.v,j);
    assert(i.v == 123 && j.v == i.v);

    d.port.in.eio2.action(i);
    assert(i.v == 246);


    assert(IDataparam.Status.Yes == d.port.in.eor.action(i));
    assert(i.v == 234);

    assert(IDataparam.Status.Yes == d.port.in.eoor.action(i,j));
    assert(i.v == 123 && j.v == 456);

    assert(IDataparam.Status.Yes == d.port.in.eior.action(i.v,j));
    assert(i.v == 123 && j.v == i.v);

    assert(IDataparam.Status.Yes == d.port.in.eio2r.action(i));
    assert(i.v == 246);
  }
}
