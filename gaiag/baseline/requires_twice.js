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

dezyne.requires_twice = function(rt, meta) {
  this.rt = rt;
  rt.components = (rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;

  this.p = new dezyne.irequires_twice({provides: {name: 'p', component: this}, requires: {}});
  this.once = new dezyne.irequires_twice({provides: {}, requires: {name: 'once', component: this}});
  this.twice = new dezyne.irequires_twice({provides: {}, requires: {name: 'twice', component: this}});

  this.p.in.e = function() {
    runtime.call_in(this, function() {
      {
        this.once.in.e();
        this.twice.in.e();
      }
    }.bind(this), [this.p, 'e']);
  }.bind(this);
  this.once.out.a = function() {
    runtime.call_out(this, function() {
      { }
    }.bind(this), [this.once, 'a']);
  }.bind(this);
  this.twice.out.a = function() {
    runtime.call_out(this, function() {
      {
        this.p.out.a();
      }
    }.bind(this), [this.twice, 'a']);
  }.bind(this);


};
