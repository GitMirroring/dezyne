// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

class Comp extends Component {
  enum State {
    Uninitialized, Initialized, Error
  };

  State s;
  IComp.result_t reply_IComp_result_t;

  IDevice.result_t reply_IDevice_result_t;


  IComp client;
  IDevice device_A;

  public Comp(Runtime runtime) {this(runtime, "");};

  public Comp(Runtime runtime, String name) {this(runtime, name, null);};

  public Comp(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    s = State.Uninitialized;
    client = new IComp();
    client.in.name = "client";
    client.in.self = this;
    s = State.Uninitialized;
    device_A = new IDevice();
    device_A.out.name = "device_A";
    device_A.out.self = this;
    client.in.initialize = new ValuedAction<IComp.result_t>() {public IComp.result_t action() {return Runtime.callIn(Comp.this, new ValuedAction<IComp.result_t>() {public IComp.result_t action() {return client_initialize();}}, new Meta(Comp.this.client, "initialize"));};};

    client.in.recover = new ValuedAction<IComp.result_t>() {public IComp.result_t action() {return Runtime.callIn(Comp.this, new ValuedAction<IComp.result_t>() {public IComp.result_t action() {return client_recover();}}, new Meta(Comp.this.client, "recover"));};};

    client.in.perform_actions = new ValuedAction<IComp.result_t>() {public IComp.result_t action() {return Runtime.callIn(Comp.this, new ValuedAction<IComp.result_t>() {public IComp.result_t action() {return client_perform_actions();}}, new Meta(Comp.this.client, "perform_actions"));};};

  };
  public IComp.result_t client_initialize() {
    if (s == State.Uninitialized) {
      {
        V<IDevice.result_t> res = new V <IDevice.result_t>(device_A.in.initialize.action());
        if (res.v == IDevice.result_t.OK) {
          res.v = device_A.in.calibrate.action();
        }
        if (res.v == IDevice.result_t.OK) {
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
      throw new RuntimeException("illegal");
    }
    else if (s == State.Error) {
      throw new RuntimeException("illegal");
    }
    return reply_IComp_result_t;
  };

  public IComp.result_t client_recover() {
    if (s == State.Uninitialized) {
      throw new RuntimeException("illegal");
    }
    else if (s == State.Initialized) {
      throw new RuntimeException("illegal");
    }
    else if (s == State.Error) {
      {
        V<IDevice.result_t> res = new V <IDevice.result_t>(device_A.in.calibrate.action());
        if (res.v == IDevice.result_t.OK) {
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
    if (s == State.Uninitialized) {
      throw new RuntimeException("illegal");
    }
    else if (s == State.Initialized) {
      {
        V<IDevice.result_t> res = new V <IDevice.result_t>(device_A.in.perform_action1.action());
        if (res.v == IDevice.result_t.OK) {
          res.v = device_A.in.perform_action2.action();
        }
        if (res.v == IDevice.result_t.OK) {
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
      throw new RuntimeException("illegal");
    }
    return reply_IComp_result_t;
  };

}
