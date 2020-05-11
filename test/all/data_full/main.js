#! /usr/bin/env node

// Dezyne --- Dezyne command line tools
// Copyright © 2016, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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

process.env.NODE_PATH += ':' + __dirname;
process.env.NODE_PATH += ':' + __dirname + '/../../javascript';
require("module").Module._initPaths();

function have_dzn_p () {return typeof (dzn) !== 'undefined' && dzn;}

assert = require ('assert');
dzn = have_dzn_p () ? dzn : require ('dzn/runtime');
dzn.extend (dzn, require ('data_full'));

/* handwritten dataparam.js */

function a0() {
  process.stdout.write('a0()\n');
  process.stderr.write('sut.p.bottom.a0 -> <external>.port.a0\n');
}

function a(i) {
  process.stdout.write('a(' + i + ')\n');
  process.stderr.write('sut.p.bottom.a -> <external>.port.a\n');
}

function aa(i, j) {
  process.stdout.write('aa(' + i + ',' + j + ')\n')
  process.stderr.write('sut.p.bottom.aa -> <external>.port.aa\n');
  console.assert(j == 123);
}

function a6(i0, i1, i2,i3, i4, i5) {
  process.stdout.write('a6(' + i0 + ',' + i1 + ',' + i2 + ',' + i3 + ',' + i4 + ',' + i5 + ')\n');
  process.stderr.write('sut.p.bottom.a6 -> <external>.port.a6\n');
  console.assert(i0 == 0);
  console.assert(i1 == 1);
  console.assert(i2 == 2);
  console.assert(i3 == 3);
  console.assert(i4 == 4);
  console.assert(i5 == 5);
}

function main() {
  var loc = new dzn.locator();
  var rt = new dzn.runtime();
  var sut = new dzn.data_full(loc.set(rt), {name: 'sut'});
  sut.port._dzn.meta.requires = {name: 'port', component: null};

  sut.port.out.a0 = a0;
  sut.port.out.a = a;
  sut.port.out.aa = aa;
  sut.port.out.a6 = a6;

  console.assert(new dzn.Idata_full().Status.Yes == sut.port.in.e0r());
  sut.port.in.e0();
  console.assert(new dzn.Idata_full().Status.Yes == sut.port.in.er(123));
  sut.port.in.e(123);
  console.assert(new dzn.Idata_full().Status.No == sut.port.in.eer(123,345));

  var i = {value:0};
  sut.port.in.eo(i);
  console.assert(i.value == 234);

  var j = {value:0};
  sut.port.in.eoo(i,j);
  console.assert(i.value == 123 && j.value == 456);

  sut.port.in.eio(i.value,j);
  console.assert(i.value == 123 && j.value == i.value);

  sut.port.in.eio2(i);
  console.assert(i.value == 246);


  console.assert(new dzn.Idata_full().Status.Yes == sut.port.in.eor(i));
  console.assert(i.value == 234);

  console.assert(new dzn.Idata_full().Status.Yes == sut.port.in.eoor(i,j));
  console.assert(i.value == 123 && j.value == 456);

  console.assert(new dzn.Idata_full().Status.Yes == sut.port.in.eior(i.value,j));
  console.assert(i.value == 123 && j.value == i.value);

  console.assert(new dzn.Idata_full().Status.Yes == sut.port.in.eio2r(i));
  console.assert(i.value == 246);
}

main();
