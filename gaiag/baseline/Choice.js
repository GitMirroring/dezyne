// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

dezyne.Choice = function(rt, meta) {
  this.rt = rt;
  rt.components = (rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;
  this.State = {
    Off: 0, Idle: 1, Busy: 2
  };
  this.State_to_string = {
    0: 'State_Off', 1: 'State_Idle', 2: 'State_Busy'
  };
  this.s = this.State.Off;

  this.c = new dezyne.IChoice({provides: {name: 'c', component: this}, requires: {}});

  this.c.in.e = function() {
    runtime.call_in(this, function() {
      if(this.s === this.State.Off) {
        this.s = this.State.Idle;
        this.c.out.a();
      }
      else if(this.s === this.State.Idle) {
        this.s = this.State.Busy;
        this.c.out.a();
      }
      else if(this.s === this.State.Busy) {
        this.s = this.State.Idle;
        this.c.out.a();
      }
    }.bind(this), [this.c, 'e']);
  }.bind(this);


};
