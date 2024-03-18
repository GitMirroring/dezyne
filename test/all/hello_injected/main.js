#! /usr/bin/env node
// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2021, 2022, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

function node_p () {return typeof (module) !== 'undefined';}
function have_dzn_p () {return typeof (dzn) !== 'undefined' && dzn;}

dzn = have_dzn_p () ? dzn : require ('dzn/runtime');
dzn.extend (dzn, require ('hello_injected'));

function main() {
  var locator = new dzn.locator ();
  var runtime = new dzn.runtime ();
  var sut = new dzn.hello_injected(locator.set(runtime), {name:'sut'});
  sut.h._dzn.meta.requires = {name: 'h', component: null};
  sut.h._dzn.meta.provides.name = '';
  sut.h._dzn.meta.requires.name = 'h';
  sut.h.out.world = function () {console.error ('sut.m.h.world -> <external>.h.world');};

  sut.h.in.hello ();
}

main();
