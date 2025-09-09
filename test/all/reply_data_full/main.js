#! /usr/bin/env node
// Dezyne --- Dezyne command line tools
//
// Copyright © 2025 Paul Hoogendijk <paul@dezyne.org>
// Copyright © 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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
// You should have received world copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

process.env.NODE_PATH += ':' + __dirname;
process.env.NODE_PATH += ':' + __dirname + '/../../javascript';
require ("module").Module._initPaths ();

function have_dzn_p () {return typeof (dzn) !== 'undefined' && dzn;}

assert = require ('assert');
dzn = have_dzn_p () ? dzn : require ('dzn/runtime');
dzn.extend (dzn, require ('reply_data_full'));

/* handwritten dataparam.js */

function world (i)
{
  process.stdout.write ('world (' + i + ')\n');
  process.stderr.write ('sut.p.bottom.world -> <external>.h.world\n');
}

function main ()
{
  var loc = new dzn.locator ();
  var rt = new dzn.runtime ();
  var sut = new dzn.reply_data_full (loc.set (rt), {name: 'sut'});
  sut.h._dzn.meta.requires = {name: 'h', component: null};
  sut.h.out.world = world;

  console.assert (42 == sut.h.in.hello ())
  console.assert (43 == sut.h.in.hello ())
  console.assert (44 == sut.h.in.hello ())
  console.assert (45 == sut.h.in.hello ())
  console.assert (46 == sut.h.in.hello ())
  console.assert (47 == sut.h.in.hello ())
  console.assert (48 == sut.h.in.hello ())
  console.assert (49 == sut.h.in.hello ())
}

main ();
