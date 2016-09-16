// Dezyne --- Dezyne command line tools
//
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

var dzn = typeof (dzn) !== undefined && dzn ? dzn : require (__dirname + '/dzn/runtime');
dzn.extend (dzn, require (__dirname + '/dzn/implicit_on'));

function main() {
  var loc = new dzn.locator();
  var rt = new dzn.runtime(function() {console.error('illegal');process.exit(0);});
  var sut = new dzn.implicit_on(loc.set(rt), {name: 'sut'});
  sut.p._dzn.meta.requires = {name: 'p', component: null};
  sut.p.in.e();
  process.exit (1);
}

main();
