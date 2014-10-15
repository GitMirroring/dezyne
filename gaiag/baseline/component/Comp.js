// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

component.Comp = function() {
  this.State= {
    Uninitialized: 0, Initialized: 1, Error: 2
  };

  this.s = this.State.Uninitialized;
  this.reply_IComp_result_t = nul;
  this.reply_IDevice_result_t = nul;

  this.client = new interface.IComp();
  this.device_A = new interface.IDevice();

  this.client.in.initialize = function() {
    console.log('Comp.client_initialize');
    if(this.s === this.State.Uninitialized) {
      {
        res = this.device_A.in.initialize();
        if(res === interface.IDevice.result_t.OK) {
          this.res = this.device_A.in.calibrate();
        }
        if(res === interface.IDevice.result_t.OK) {
          this.s = this.State.Initialized;
          this.reply_IDevice_result_t = interface.IDevice.result_t.OK;
        }
        else {
          this.s = this.State.Uninitialized;
          this.reply_IDevice_result_t = interface.IDevice.result_t.NOK;
        }
      }
    }
    else if(this.s === this.State.Initialized) {
      assert (false);
    }
    else if(this.s === this.State.Error) {
      assert (false);
    }
    return self.reply_IComp_result_t;
  }.bind(this);
  this.client.in.recover = function() {
    console.log('Comp.client_recover');
    if(this.s === this.State.Uninitialized) {
      assert (false);
    }
    else if(this.s === this.State.Initialized) {
      assert (false);
    }
    else if(this.s === this.State.Error) {
      {
        res = this.device_A.in.calibrate();
        if(res === interface.IDevice.result_t.OK) {
          this.s = this.State.Initialized;
          this.reply_IDevice_result_t = interface.IDevice.result_t.OK;
        }
        else {
          this.s = this.State.Error;
          this.reply_IDevice_result_t = interface.IDevice.result_t.NOK;
        }
      }
    }
    return self.reply_IComp_result_t;
  }.bind(this);
  this.client.in.perform_actions = function() {
    console.log('Comp.client_perform_actions');
    if(this.s === this.State.Uninitialized) {
      assert (false);
    }
    else if(this.s === this.State.Initialized) {
      {
        res = this.device_A.in.perform_action1();
        if(res === interface.IDevice.result_t.OK) {
          this.res = this.device_A.in.perform_action2();
        }
        if(res === interface.IDevice.result_t.OK) {
          this.s = this.State.Initialized;
          this.reply_IDevice_result_t = interface.IDevice.result_t.OK;
        }
        else {
          this.s = this.State.Error;
          this.reply_IDevice_result_t = interface.IDevice.result_t.NOK;
        }
      }
    }
    else if(this.s === this.State.Error) {
      assert (false);
    }
    return self.reply_IComp_result_t;
  }.bind(this);

};
