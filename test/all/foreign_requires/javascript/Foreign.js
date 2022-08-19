// Dezyne --- Dezyne command line tools
//
// Copyright © 2018, 2020, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

dzn_require = typeof (require) !== 'undefined' ? require : function () {return {};};
dzn = typeof (dzn) !== 'undefined' ? dzn : require (__dirname + '/runtime');
dzn = dzn || {};

dzn.Foreign = function (locator, meta) {
  dzn.runtime.init (this, locator, meta);
  this._dzn.meta.ports = ['h', 'w0', 'w1'];

  this.h = new dzn.ihello ({provides: {name: 'w0', component: this}, requires: {}});
  this.w0 = new dzn.ihello ({provides: {}, requires: {name: 'w0', component: this}});
  this.w1 = new dzn.ihello ({provides: {}, requires: {name: 'w1', component: this}});
  this.h.in.hello = function () {}
  this.w0.out.world = function () {this.w0.in.hello ();};
  this.w1.out.world = function () {this.w1.in.hello ();};
  this.w0.world = function () {this.w0.in.hello ();};
  this.w1.world = function () {this.w1.in.hello ();};

  this._dzn.rt.bind (this);
};

if (typeof (module) !== 'undefined') {
  module.exports = dzn;
}
