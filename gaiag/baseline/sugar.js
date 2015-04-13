// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

dezyne.sugar = function(rt, meta) {
  this.rt = rt;
  rt.components = (rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;
  this.Enum = {
    False: 0, True: 1
  };
  this.Enum_to_string = {
    0: 'Enum_False', 1: 'Enum_True'
  };
  this.s = this.Enum.False;

  this.i = new dezyne.I({provides: {name: 'i', component: this}, requires: {}});

  this.i.in.e = function() {
    runtime.call_in(this, function() {
      if(this.s === this.Enum.False) if(this.s === this.Enum.False) this.i.out.a();
      else {
        var t = {value: this.Enum.False};
        if(t.value === this.Enum.True) this.i.out.a();
      }
    }.bind(this), [this.i, 'e']);
  }.bind(this);


};
