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

function timer(locator, meta) {
  this._dzn = {};
  this._dzn.locator = locator;
  this._dzn.rt = locator.get(new dzn.runtime());
  this._dzn.rt.components = (this.rt.components || []).concat ([this]);
  this._dzn.meta = meta;

  this.port = new dzn.itimer({provides: {name: 'port', component: this}, requires: {}});
  this.port.in.create = function(ms) {
  }
  this.port.in.cancel = function() {
  }
  this._dzn.rt.bind (this);
};

dzn.timer = timer;
