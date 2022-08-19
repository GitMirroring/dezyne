#! /usr/bin/env node
// Dezyne --- Dezyne command line tools
//
// Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

process.env.NODE_PATH += ':' + __dirname;
process.env.NODE_PATH += ':' + __dirname + '/../../javascript';
require("module").Module._initPaths();

function node_p () {return typeof (module) !== 'undefined';}
function have_dzn_p () {return typeof (dzn) !== 'undefined' && dzn;}

dzn = have_dzn_p () ? dzn : require ('dzn/runtime');
dzn.extend (dzn, require ('Foreign'));
dzn.extend (dzn, require ('foreign_requires'));

function main () {
  var loc = new dzn.locator();
  var pump = new dzn.pump();
  loc.set(pump);
  var rt = new dzn.runtime(function() {console.error('illegal');process.exit(1);});
  var sut = new dzn.foreign_requires(loc.set(rt), {name:'sut'});

  sut.c.w0.in.hello = function () {
    console.error ('<external>.w0.hello -> sut.c.h.hello');
    console.error ('<external>.w0.return -> sut.c.h.return');
  };
  sut.c.w1.in.hello = function () {
    console.error ('<external>.w1.hello -> sut.c.h.hello');
    console.error ('<external>.w1.return -> sut.c.h.return');
  };
  sut.f.w0.out.world ();
  sut.f._dzn.rt.flush (sut.f);
  sut.f.w1.out.world ();
  sut.f._dzn.rt.flush (sut.f);
}

main ();
