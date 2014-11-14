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

class Comp{
  enum State {
    Uninitialized, Initialized, Error
  };

  State s;
  IComp.result_t reply_IComp_result_t;

  IDevice.result_t reply_IDevice_result_t;


  IComp client;
  IDevice device_A;

  public Comp() {
    s = State.Uninitialized;
    client = new IComp();
    device_A = new IDevice();
    client.getIn().initialize = new ValuedAction<IComp.result_t>() {
      public IComp.result_t action() {
        return client_initialize();
      }
    };
    client.getIn().recover = new ValuedAction<IComp.result_t>() {
      public IComp.result_t action() {
        return client_recover();
      }
    };
    client.getIn().perform_actions = new ValuedAction<IComp.result_t>() {
      public IComp.result_t action() {
        return client_perform_actions();
      }
    };
  };
  public IComp.result_t client_initialize() {
    System.err.println("Comp.client_initialize");
    if (s == State.Uninitialized) {
      {
        IDevice.result_t res = device_A.getIn().initialize.action();
        if (res == IDevice.result_t.OK) {
          res = device_A.getIn().calibrate.action();
        }
        if (res == IDevice.result_t.OK) {
          s = State.Initialized;
          reply_IDevice_result_t = IDevice.result_t.OK;
        }
        else {
          s = State.Uninitialized;
          reply_IDevice_result_t = IDevice.result_t.NOK;
        }
      }
    }
    else if (s == State.Initialized) {
      assert(false);
    }
    else if (s == State.Error) {
      assert(false);
    }
    return reply_IComp_result_t;
  };

  public IComp.result_t client_recover() {
    System.err.println("Comp.client_recover");
    if (s == State.Uninitialized) {
      assert(false);
    }
    else if (s == State.Initialized) {
      assert(false);
    }
    else if (s == State.Error) {
      {
        IDevice.result_t res = device_A.getIn().calibrate.action();
        if (res == IDevice.result_t.OK) {
          s = State.Initialized;
          reply_IDevice_result_t = IDevice.result_t.OK;
        }
        else {
          s = State.Error;
          reply_IDevice_result_t = IDevice.result_t.NOK;
        }
      }
    }
    return reply_IComp_result_t;
  };

  public IComp.result_t client_perform_actions() {
    System.err.println("Comp.client_perform_actions");
    if (s == State.Uninitialized) {
      assert(false);
    }
    else if (s == State.Initialized) {
      {
        IDevice.result_t res = device_A.getIn().perform_action1.action();
        if (res == IDevice.result_t.OK) {
          res = device_A.getIn().perform_action2.action();
        }
        if (res == IDevice.result_t.OK) {
          s = State.Initialized;
          reply_IDevice_result_t = IDevice.result_t.OK;
        }
        else {
          s = State.Error;
          reply_IDevice_result_t = IDevice.result_t.NOK;
        }
      }
    }
    else if (s == State.Error) {
      assert(false);
    }
    return reply_IComp_result_t;
  };

}
