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

function* producer(x) {
  console.log('*producer x=' + x);
  var v;
  while (true) {
    console.log('Hello v=' + v);
    v = yield 'p';
  }
}

function* consumer(x) {
  console.log('*consumer x=' + x);
  var v;
  while (true) {
    console.log('world v=' +v);
    v = yield 'c';
  }
}

var co = {produce:producer('a'),consume:consumer('b')}
co.produce.next ('c');
co.consume.next ('d');

var x = {};
var i = 0;
while (true) {
  x = co.produce.next (x.value);
  if (x.done) break;
  x = co.consume.next (x.value);
  if (x.done) break;
  if (!(i++ % 10)) {console.log ('gc'); global.gc ();}
}
