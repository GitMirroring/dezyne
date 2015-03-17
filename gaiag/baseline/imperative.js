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

dezyne.imperative = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.States = {
    I: 0, II: 1, III: 2, IV: 3
  };
  this.States_to_string = {
    0: 'States_I', 1: 'States_II', 2: 'States_III', 3: 'States_IV'
  };
  this.state = this.States.I;

  this.i = new dezyne.iimperative({provides: {name: 'i', component: this}, requires: {}});

  this.i.in.e = function() {
    runtime.call_in(this, function() {
      if(this.state === this.States.I) {
        this.i.out.f();
        this.i.out.g();
        this.i.out.h();
        this.state = this.States.II;
      }
      else if(this.state === this.States.II) {
        this.state = this.States.III;
      }
      else if(this.state === this.States.III) {
        this.i.out.f();
        this.i.out.g();
        this.i.out.g();
        this.i.out.f();
        this.state = this.States.IV;
      }
      else if(this.state === this.States.IV) {
        this.i.out.h();
        this.state = this.States.I;
      }
    }.bind(this), [this.i, 'e']);
  }.bind(this);

};
