// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

dezyne.Comp = function() {
  this.State = {
    Uninitialized: 0, Initialized: 1, Error: 2
  };
  this.s = this.State.Uninitialized;
  this.reply_IComp_result_t = null;
  this.reply_IDevice_result_t = null;

  this.client = new dezyne.IComp();
  this.device_A = new dezyne.IDevice();

  this.client.in.initialize = function() {
    console.log('Comp.client_initialize');
    if(this.s === this.State.Uninitialized) {
      {
        var res = this.device_A.in.initialize();
        if(res === new dezyne.IDevice().result_t.OK) {
          res = this.device_A.in.calibrate();
        }
        if(res === new dezyne.IDevice().result_t.OK) {
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
  }.bind(this);
  this.client.in.recover = function() {
    console.log('Comp.client_recover');
    if(this.s === this.State.Uninitialized) {
      console.assert (false);
    }
    else if(this.s === this.State.Initialized) {
      console.assert (false);
    }
    else if(this.s === this.State.Error) {
      {
        var res = this.device_A.in.calibrate();
        if(res === new dezyne.IDevice().result_t.OK) {
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
  }.bind(this);
  this.client.in.perform_actions = function() {
    console.log('Comp.client_perform_actions');
    if(this.s === this.State.Uninitialized) {
      console.assert (false);
    }
    else if(this.s === this.State.Initialized) {
      {
        var res = this.device_A.in.perform_action1();
        if(res === new dezyne.IDevice().result_t.OK) {
          res = this.device_A.in.perform_action2();
        }
        if(res === new dezyne.IDevice().result_t.OK) {
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
  }.bind(this);

};
