// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

dezyne.function = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.f = false;

  this.i = new dezyne.I({provides: {name: 'i', component: this}, requires: {}});

  this.i.in.a = function() {
    runtime.call_in(this, function() {
      if(true) {
        {
          this.toggle();
        }
      }
    }.bind(this), [this.i, 'a']);
  }.bind(this);
  this.i.in.b = function() {
    runtime.call_in(this, function() {
      if(true) {
        {
          this.toggle();
          this.toggle();
          this.i.out.d();
        }
      }
    }.bind(this), [this.i, 'b']);
  }.bind(this);
  this.toggle = function () {
    if(this.f) {
      this.i.out.c();
    }
    this.f = ! (this.f);
  }.bind(this);

};
