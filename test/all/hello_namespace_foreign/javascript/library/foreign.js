// Dezyne --- Dezyne command line tools
//
// Copyright © 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
function node_p () {return typeof module !== 'undefined';}
function have_dzn_p () {return typeof (dzn) !== 'undefined' && dzn;}

dzn = dzn || {};
dzn.library = dzn.library || {};

dzn.library.foreign = function (locator, meta) {
  dzn.runtime.init (this, locator, meta);
  this._dzn.meta.ports = ['w'];
  //this._dzn.flushes = true;
  this.w = new dzn.library.iworld({provides: {name: 'w', component: this}, requires: {}});
  this.w.in.world = function(){}
  this._dzn.rt.bind (this);
};

if (node_p ()) {
  // nodejs
  module.exports = dzn;
}
