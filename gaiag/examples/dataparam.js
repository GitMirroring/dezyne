// Dezyne --- Dezyne command line tools
//
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


/* handwritten dataparam.js */

function a0() {
  console.log('a0()');
}

function a(i) {
  console.log('a(' + i + ')');
}

function aa(i, j) {
  console.log ('aa(' + i + ',' + j + ')')
}

function a6(i0, i1, i2,i3, i4, i5) {
  console.log('a6(' + i0 + ',' + i1 + ',' + i2 + ',' + i3 + ',' + i4 + ',' + i5 + ')');
}

function main() {
  var c = new dezyne.Dataparam();

  c.port.out.a0 = a0;
  c.port.out.a = a;
  c.port.out.aa = aa;
  c.port.out.a6 = a6;

  console.assert(new dezyne.IDataparam().Status.Yes == c.port.in.e0r());
  c.port.in.e0();
  console.assert(new dezyne.IDataparam().Status.Yes == c.port.in.er(123));
  c.port.in.e(123);
  console.assert(new dezyne.IDataparam().Status.No == c.port.in.eer(123,345));

  var i = {value:0};
  c.port.in.eo(i);
  console.assert(i.value == 234);

  var j = {value:0};
  c.port.in.eoo(i,j);
  console.assert(i.value == 123 && j.value == 456);

  c.port.in.eio(i.value,j);
  console.assert(i.value == 123 && j.value == i.value);

  c.port.in.eio2(i);
  console.assert(i.value == 246);


  console.assert(new dezyne.IDataparam().Status.Yes == c.port.in.eor(i));
  console.assert(i.value == 234);

  console.assert(new dezyne.IDataparam().Status.Yes == c.port.in.eoor(i,j));
  console.assert(i.value == 123 && j.value == 456);

  console.assert(new dezyne.IDataparam().Status.Yes == c.port.in.eior(i.value,j));
  console.assert(i.value == 123 && j.value == i.value);

  console.assert(new dezyne.IDataparam().Status.Yes == c.port.in.eio2r(i));
  console.assert(i.value == 246);
}

main();
