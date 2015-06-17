// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
  this.locator = locator;
  this.rt = locator.get(dezyne.runtime);
  this.rt.components = (this.rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;

  this.port = new dezyne.itimer({provides: {name: 'port', component: this}, requires: {}});
  this.port.in.create = function(ms) {
    this.rt.call_in(this, function() {
      { }
    }.bind(this), [this.port, 'create']);
  }.bind(this);
  this.port.in.cancel = function() {
    this.rt.call_in(this, function() {
      { }
    }.bind(this), [this.port, 'cancel']);
  }.bind(this);


};

dezyne.timer = timer;
