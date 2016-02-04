// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

#! /usr/bin/env node

var dezyne = typeof (dezyne) !== undefined && dezyne ? dezyne : require (__dirname + '/dezyne/runtime');
dezyne.extend (dezyne, require (__dirname + '/dezyne/Injected'));

function main() {
  var loc = new dezyne.locator();
  var rt = new dezyne.runtime();
  var sut = new dezyne.Injected(loc.set(rt), 'sut');
  sut.t.out.f = function() {console.error('f');};

  //sut.check_bindings();
  //sut.dump_tree();

  sut.t.in.e();
}

main();
