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

dezyne.complete = function(rt, meta) {
  this.rt = rt;
  rt.components = (rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;

  this.p = new dezyne.icomplete({provides: {name: 'p', component: this}, requires: {}});
  this.r = new dezyne.icomplete({provides: {}, requires: {name: 'r', component: this}});

  this.p.in.e = function() {
    runtime.call_in(this, function() {
      {
        this.r.in.e();
      }
    }.bind(this), [this.p, 'e']);
  }.bind(this);
  this.r.out.a = function() {
    runtime.call_out(this, function() {
      {
        this.p.out.a();
      }
    }.bind(this), [this.r, 'a']);
  }.bind(this);


};
