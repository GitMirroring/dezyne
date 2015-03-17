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

dezyne.function2 = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.f = false;

  this.i = new dezyne.ifunction2({provides: {name: 'i', component: this}, requires: {}});

  this.i.in.a = function() {
    runtime.call_in(this, function() {
      if(true) {
        {
          if (typeof(this.f) === 'object') this.f.value = this.vtoggle(); else this.f = this.vtoggle()
        }
      }
    }.bind(this), [this.i, 'a']);
  }.bind(this);
  this.i.in.b = function() {
    runtime.call_in(this, function() {
      if(true) {
        {
          if (typeof(this.f) === 'object') this.f.value = this.vtoggle(); else this.f = this.vtoggle()
          var bb = {value: this.vtoggle()};
          if (typeof(this.f) === 'object') this.f.value = ((typeof(bb) === 'object') ? bb.value : bb); else this.f = ((typeof(bb) === 'object') ? bb.value : bb); 
          this.i.out.d();
        }
      }
    }.bind(this), [this.i, 'b']);
  }.bind(this);
  this.vtoggle = function () {
    if(this.f) this.i.out.c();
    return ! (this.f);
  }.bind(this);

};
