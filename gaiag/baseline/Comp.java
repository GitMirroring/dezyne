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

// header
//package dezyne;

import java.lang.Runnable;

abstract class Action<R> {
  public abstract R action();
}

abstract class Function extends Action<Void> {
  public abstract Void action();
}

@SuppressWarnings("unchecked")
abstract class Interface<I extends Interface.In, O extends Interface.Out> {
  interface In {
  }
  interface Out {
  }

  protected In in;
  protected Out out;

  public I getIn() {
    return (I) in;
  }

  public void setIn(I in) {
    this.in = in;
  }

  public O getOut() {
    return (O) out;
  }

  public void setOut(O out) {
    this.out = out;
  }

  @SuppressWarnings("rawtypes")
    public static void connect(Interface provided, Interface required) {
    provided.setOut(required.getOut());
    required.setIn(provided.getIn());
  };
}
// end header
class IDevice extends Interface<IDevice.In, IDevice.Out> {
  enum result_t {
    OK, NOK
  };
  class In implements Interface.In {
    Action<result_t> initialize;
    Action<result_t> calibrate;
    Action<result_t> perform_action1;
    Action<result_t> perform_action2;
  }
  class Out implements Interface.Out {

  }
  public IDevice() {
    in = new In();
    out = new Out();
  }
}
class IComp extends Interface<IComp.In, IComp.Out> {
  enum result_t {
    OK, NOK
  };
  class In implements Interface.In {
    Action initialize;
    Action recover;
    Action perform_actions;
  }
  class Out implements Interface.Out {

  }
  public IComp() {
    in = new In();
    out = new Out();
  }
}
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
    client = new IComp();
    device_A = new IDevice();
    client.getIn().initialize = new Action() {
      public IDevice.result_t action() {
        return client_initialize();
      }
    };
    client.getIn().recover = new Action() {
      public IDevice.result_t action() {
        return client_recover();
      }
    };
    client.getIn().perform_actions = new Action() {
      public IDevice.result_t action() {
        return client_perform_actions();
      }
    };
  };
  public IDevice.result_t client_initialize() {
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
    return reply_IDevice_result_t;
  };

  public IDevice.result_t client_recover() {
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
    return reply_IDevice_result_t;
  };

  public IDevice.result_t client_perform_actions() {
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
    return reply_IDevice_result_t;
  };

}
