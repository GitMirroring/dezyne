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

dezyne.Comp = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.State = {
    Uninitialized: 0, Initialized: 1, Error: 2
  };
  this.State_to_string = {
    0: 'State_Uninitialized', 1: 'State_Initialized', 2: 'State_Error'
  };
  this.s = this.State.Uninitialized;
  this.reply_IComp_result_t = null;
  this.reply_IDevice_result_t = null;

  this.client = new dezyne.IComp({provides: {name: 'client', component: this}, requires: {}});
  this.device_A = new dezyne.IDevice({provides: {}, requires: {name: 'device_A', component: this}});

  this.client.in.initialize = function() {
    return runtime.call_in(this, function() {
      if(this.s === this.State.Uninitialized) {
        {
          var res = {value: this.device_A.in.initialize()};
          if(res.value === new dezyne.IDevice().result_t.OK) {
            res.value = this.device_A.in.calibrate();
          }
          if(res.value === new dezyne.IDevice().result_t.OK) {
            this.s = this.State.Initialized;
            this.reply_IDevice_result_t = new dezyne.IDevice().result_t.OK;
          }
          else {
            this.s = this.State.Uninitialized;
            this.reply_IDevice_result_t = new dezyne.IDevice().result_t.NOK;
          }
        }
      }
      else if(this.s === this.State.Initialized) {
        console.assert (false);
      }
      else if(this.s === this.State.Error) {
        console.assert (false);
      }
      return this.reply_IComp_result_t;
    }.bind(this), [this.client, 'initialize', this.client.result_t_to_string]);
  }.bind(this);
  this.client.in.recover = function() {
    return runtime.call_in(this, function() {
      if(this.s === this.State.Uninitialized) {
        console.assert (false);
      }
      else if(this.s === this.State.Initialized) {
        console.assert (false);
      }
      else if(this.s === this.State.Error) {
        {
          var res = {value: this.device_A.in.calibrate()};
          if(res.value === new dezyne.IDevice().result_t.OK) {
            this.s = this.State.Initialized;
            this.reply_IDevice_result_t = new dezyne.IDevice().result_t.OK;
          }
          else {
            this.s = this.State.Error;
            this.reply_IDevice_result_t = new dezyne.IDevice().result_t.NOK;
          }
        }
      }
      return this.reply_IComp_result_t;
    }.bind(this), [this.client, 'recover', this.client.result_t_to_string]);
  }.bind(this);
  this.client.in.perform_actions = function() {
    return runtime.call_in(this, function() {
      if(this.s === this.State.Uninitialized) {
        console.assert (false);
      }
      else if(this.s === this.State.Initialized) {
        {
          var res = {value: this.device_A.in.perform_action1()};
          if(res.value === new dezyne.IDevice().result_t.OK) {
            res.value = this.device_A.in.perform_action2();
          }
          if(res.value === new dezyne.IDevice().result_t.OK) {
            this.s = this.State.Initialized;
            this.reply_IDevice_result_t = new dezyne.IDevice().result_t.OK;
          }
          else {
            this.s = this.State.Error;
            this.reply_IDevice_result_t = new dezyne.IDevice().result_t.NOK;
          }
        }
      }
      else if(this.s === this.State.Error) {
        console.assert (false);
      }
      return this.reply_IComp_result_t;
    }.bind(this), [this.client, 'perform_actions', this.client.result_t_to_string]);
  }.bind(this);

};
