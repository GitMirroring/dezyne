// Dezyne --- Dezyne command line tools
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

dezyne.Guardthreetopon = function(rt, meta) {
  this.rt = rt;
  rt.components = (rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;
  this.b = false;

  this.i = new dezyne.IGuardthreetopon({provides: {name: 'i', component: this}, requires: {}});
  this.r = new dezyne.RGuardthreetopon({provides: {}, requires: {name: 'r', component: this}});

  this.i.in.e = function() {
    runtime.call_in(this, function() {
      if(true && this.b) {
        this.i.out.a();
      }
      else if(true && ! (this.b)) {
        var c = {value: true};
        if(c.value) this.i.out.a();
      }
    }.bind(this), [this.i, 'e']);
  }.bind(this);
  this.i.in.t = function() {
    runtime.call_in(this, function() {
      if(this.b) this.i.out.a();
      else if(! (this.b)) this.i.out.a();
    }.bind(this), [this.i, 't']);
  }.bind(this);
  this.i.in.s = function() {
    runtime.call_in(this, function() {
      this.i.out.a();
    }.bind(this), [this.i, 's']);
  }.bind(this);
  this.r.out.a = function() {
    runtime.call_out(this, function() {
      { }
    }.bind(this), [this.r, 'a']);
  }.bind(this);

};
