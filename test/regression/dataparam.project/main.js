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

#! /usr/bin/nodejs

var dezyne = require (__dirname + '/dezyne/runtime');
dezyne.extend (dezyne, require (__dirname + '/dezyne/Datasystem'));

/* handwritten dataparam.js */

function a0() {
  process.stderr.write('a0()\n');
}

function a(i) {
  process.stderr.write('a(' + i + ')\n');
}

function aa(i, j) {
  process.stderr.write('aa(' + i + ',' + j + ')\n')
  console.assert(j == 123);
}

function a6(i0, i1, i2,i3, i4, i5) {
  process.stderr.write('a6(' + i0 + ',' + i1 + ',' + i2 + ',' + i3 + ',' + i4 + ',' + i5 + ')\n');
  console.assert(i0 == 0);
  console.assert(i1 == 1);
  console.assert(i2 == 2);
  console.assert(i3 == 3);
  console.assert(i4 == 4);
  console.assert(i5 == 5);
}

function main() {
  var loc = new dezyne.locator();
  var rt = new dezyne.runtime();
  var d = new dezyne.Datasystem(loc.set(rt), {name: 'd'});
  d.port.meta.requires = {name: 'port', component: null};

  d.port.out.a0 = a0;
  d.port.out.a = a;
  d.port.out.aa = aa;
  d.port.out.a6 = a6;

  console.assert(new dezyne.IDataparam().Status.Yes == d.port.in.e0r());
  d.port.in.e0();
  console.assert(new dezyne.IDataparam().Status.Yes == d.port.in.er(123));
  d.port.in.e(123);
  console.assert(new dezyne.IDataparam().Status.No == d.port.in.eer(123,345));

  var i = {value:0};
  d.port.in.eo(i);
  console.assert(i.value == 234);

  var j = {value:0};
  d.port.in.eoo(i,j);
  console.assert(i.value == 123 && j.value == 456);

  d.port.in.eio(i.value,j);
  console.assert(i.value == 123 && j.value == i.value);

  d.port.in.eio2(i);
  console.assert(i.value == 246);


  console.assert(new dezyne.IDataparam().Status.Yes == d.port.in.eor(i));
  console.assert(i.value == 234);

  console.assert(new dezyne.IDataparam().Status.Yes == d.port.in.eoor(i,j));
  console.assert(i.value == 123 && j.value == 456);

  console.assert(new dezyne.IDataparam().Status.Yes == d.port.in.eior(i.value,j));
  console.assert(i.value == 123 && j.value == i.value);

  console.assert(new dezyne.IDataparam().Status.Yes == d.port.in.eio2r(i));
  console.assert(i.value == 246);
}

main();
