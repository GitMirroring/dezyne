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

dezyne.Adaptor = function(rt, meta) {
  this.rt = rt;
  rt.components = (rt.components || []).concat ([this]);
  this.meta = meta;
  this.flushes = true;
  this.State = {
    Idle: 0, Active: 1, Terminating: 2
  };
  this.State_to_string = {
    0: 'State_Idle', 1: 'State_Active', 2: 'State_Terminating'
  };
  this.state = this.State.Idle;
  this.count = 0;

  this.runner = new dezyne.IRun({provides: {name: 'runner', component: this}, requires: {}});
  this.choice = new dezyne.IChoice({provides: {}, requires: {name: 'choice', component: this}});

  this.runner.in.run = function() {
    runtime.call_in(this, function() {
      if(this.state === this.State.Idle && this.count < 2) {
        this.choice.in.e();
        this.state = this.State.Active;
      }
      else if(this.state === this.State.Idle && ! (this.count < 2)) { }
      else if(this.state === this.State.Active) {
        { }
      }
      else if(this.state === this.State.Terminating) { }
    }.bind(this), [this.runner, 'run']);
  }.bind(this);
  this.choice.out.a = function() {
    runtime.call_out(this, function() {
      if(this.state === this.State.Idle) { }
      else if(this.state === this.State.Active) {
        {
          this.count = this.count + 1;
          this.choice.in.e();
          this.state = this.State.Terminating;
        }
      }
      else if(this.state === this.State.Terminating && this.count < 2) {
        this.choice.in.e();
        this.state = this.State.Active;
      }
      else if(this.state === this.State.Terminating && ! (this.count < 2)) this.state = this.State.Idle;
    }.bind(this), [this.choice, 'a']);
  }.bind(this);

};
