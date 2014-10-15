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

abstract class Action<R> {
  public abstract R action();
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
class IConsole extends Interface<IConsole.In, IConsole.Out> {
  class In implements Interface.In {
    Action<Void> arm;
    Action<Void> disarm;
  }
  class Out implements Interface.Out {
    Action <Void> detected;
    Action <Void> deactivated;
  }
  public IConsole() {
    in = new In();
    out = new Out();
  }
}
class ISiren extends Interface<ISiren.In, ISiren.Out> {
  class In implements Interface.In {
    Action<Void> turnon;
    Action<Void> turnoff;
  }
  class Out implements Interface.Out {

  }
  public ISiren() {
    in = new In();
    out = new Out();
  }
}
class ISensor extends Interface<ISensor.In, ISensor.Out> {
  class In implements Interface.In {
    Action<Void> enable;
    Action<Void> disable;
  }
  class Out implements Interface.Out {
    Action <Void> triggered;
    Action <Void> disabled;
  }
  public ISensor() {
    in = new In();
    out = new Out();
  }
}
class AlarmSystem {
  Alarm alarm;
  Sensor sensor;
  Siren siren;
  IConsole console;

  public AlarmSystem() {
    alarm = new Alarm();
    sensor = new Sensor();
    siren = new Siren();
    console = alarm.console;

    Interface.connect(sensor.sensor, alarm.sensor);
    Interface.connect(siren.siren, alarm.siren);
  };
}
class Alarm{
  enum States {
    Disarmed, Armed, Triggered, Disarming
  };

  States state;
  Boolean sounding;

  IConsole console;
  ISensor sensor;
  ISiren siren;

  public Alarm() {
    state = States.Disarmed;
    sounding = false;
    console = new IConsole();
    sensor = new ISensor();
    siren = new ISiren();
    console.getIn().arm = new Action<Void>() {
      public Void action() {
        console_arm(); return null;
      }
    };
    console.getIn().disarm = new Action<Void>() {
      public Void action() {
        console_disarm(); return null;
      }
    };
    sensor.getOut().triggered = new Action<Void>() {
      public Void action() {
        sensor_triggered(); return null;
      }
    };
    sensor.getOut().disabled = new Action<Void>() {
      public Void action() {
        sensor_disabled(); return null;
      }
    };
  };
  public void console_arm() {
    System.err.println("Alarm.console_arm");
    if (state == States.Disarmed) {
      {
        sensor.getIn().enable.action();
        state = States.Armed;
      }
    }
    else if (state == States.Armed) {
      assert(false);
    }
    else if (state == States.Disarming) {
      assert(false);
    }
    else if (state == States.Triggered) {
      assert(false);
    }
  };

  public void console_disarm() {
    System.err.println("Alarm.console_disarm");
    if (state == States.Disarmed) {
      assert(false);
    }
    else if (state == States.Armed) {
      {
        sensor.getIn().disable.action();
        state = States.Disarming;
      }
    }
    else if (state == States.Disarming) {
      assert(false);
    }
    else if (state == States.Triggered) {
      {
        sensor.getIn().disable.action();
        siren.getIn().turnoff.action();
        sounding = false;
        state = States.Disarming;
      }
    }
  };

  public void sensor_triggered() {
    System.err.println("Alarm.sensor_triggered");
    if (state == States.Disarmed) {
      assert(false);
    }
    else if (state == States.Armed) {
      {
        console.getOut().detected.action();
        siren.getIn().turnon.action();
        sounding = true;
        state = States.Triggered;
      }
    }
    else if (state == States.Disarming) {
      { }
    }
    else if (state == States.Triggered) {
      assert(false);
    }
  };

  public void sensor_disabled() {
    System.err.println("Alarm.sensor_disabled");
    if (state == States.Disarmed) {
      assert(false);
    }
    else if (state == States.Armed) {
      assert(false);
    }
    else if (state == States.Disarming) {
      {
        if (sounding) {
          console.getOut().deactivated.action();
          siren.getIn().turnoff.action();
          state = States.Disarmed;
          sounding = false;
        }
        else {
          console.getOut().deactivated.action();
          state = States.Disarmed;
        }
      }
    }
    else if (state == States.Triggered) {
      assert(false);
    }
  };

}
// Handwritten
class Console {
  IConsole console;
  public Console() {
    console = new IConsole();
    console.getOut().detected = new Action<Void>() {
        public Void action() {
          System.err.println("Alarm detected");
          return null;
        }
      };
    console.getOut().deactivated = new Action<Void>() {
        public Void action() {
          System.err.println("Alarm deactivated");
          return null;
        }
      };
  }
}

class Sensor {
  ISensor sensor;
  public Sensor() {
    sensor = new ISensor();
    sensor.getIn().enable = new Action<Void>() {
        public Void action() {
          System.err.println("Sensor detected");
          return null;
        }
      };
    sensor.getIn().disable = new Action<Void>() {
        public Void action() {
          System.err.println("Sensor deactivated");
          return null;
        }
      };
  }
}

class Siren {
  ISiren siren;
  public Siren() {
    siren = new ISiren();
    siren.getIn().turnon = new Action<Void>() {
        public Void action() {
          System.err.println("Siren detected");
          return null;
        }
      };
    siren.getIn().turnoff = new Action<Void>() {
        public Void action() {
          System.err.println("Siren deactivated");
          return null;
        }
      };
  }
}

class alarm {
  public static void main(String[] args) {
    System.err.println("alarm main");
    AlarmSystem alarm = new AlarmSystem();
    Console console = new Console();
    Interface.connect(alarm.console, console.console);

    // Test trace

    alarm.console.getIn().arm.action();
    alarm.sensor.sensor.getOut().triggered.action();
    alarm.console.getIn().disarm.action();
    alarm.sensor.sensor.getOut().disabled.action();
  }
}
