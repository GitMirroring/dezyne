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
import java.lang.Runnable;

class Action implements Runnable
{
  public void run()
  {
    action();
  };
  public void action()
  {
  };
}

class Interface
{
  class In
  {
  };
  In in;
  class Out
  {
  }
  Out out;

  public static void connect(Interface provided, Interface required)
  {
    provided.out = required.out;
    required.in = provided.in;
  };
}
// end header

class IConsole extends Interface
{
  class In extends Interface.In
  {
    Action arm;
    Action disarm;
  };
  In in;
  class Out extends Interface.Out
  {
    Action detected;
    Action deactivated;
  };
  Out out;
  public IConsole()
  {
    in = new In();
    out = new Out();
  }
}

class ISiren extends Interface
{
  class In extends Interface.In
  {
    Action turnon;
    Action turnoff;
  }
  In in;
  class Out extends Interface.Out
  {
  }
  Out out;
  public ISiren()
  {
    in = new In();
    out = new Out();
  }
}

class ISensor extends Interface
{
  class In extends Interface.In
  {
    Action enable;
    Action disable;
  }
  In in;
  class Out extends Interface.Out
  {
    Action triggered;
    Action disabled;
  }
  Out out;
  public ISensor()
  {
    in = new In();
    out = new Out();
  }
}

class AlarmSystem
{
  Alarm alarm;
  Sensor sensor;
  Siren siren;
  IConsole console;

  public AlarmSystem()
  {
    sensor = new Sensor();
    siren = new Siren();
    alarm = new Alarm();
    console = alarm.console;
    Interface.connect(sensor.sensor, alarm.sensor);
    Interface.connect(siren.siren, alarm.siren);
  }
}

class Alarm
{
  enum States
  {
    Disarmed, Armed, Triggered, Disarming
  };
  States state;
  Boolean sounding;
  IConsole console;
  ISensor sensor;
  ISiren siren;
  public Alarm()
  {
    console = new IConsole();
    sensor = new ISensor();
    siren = new ISiren();
    console.in.arm = new Action()
      {
        public void action()
        {
          console_arm();
        }
      };
    console.in.disarm = new Action()
      {
        public void action()
        {
          console_disarm();
        }
      };
    sensor.out.triggered = new Action()
      {
        public void action()
        {
          sensor_triggered();
        }
      };
    sensor.out.disabled = new Action()
      {
        public void action()
        {
          sensor_disabled();
        }
      };

  }

  public void console_arm()
  {
    System.err.println("Alarm.console_arm");
    if (state == States.Disarmed)
    {
      {
        sensor.in.enable.action();
        state = States.Armed;
      }
    }
    else if (state == States.Armed)
    {
      assert(false);
    }
    else if (state == States.Disarming)
    {
      assert(false);
    }
    else if (state == States.Triggered)
    {
      assert(false);
    }
  }

  public void console_disarm()
  {
    System.err.println("Alarm.console_disarm");
    if (state == States.Disarmed)
    {
      assert(false);
    }
    else if (state == States.Armed)
    {
      {
        sensor.in.disable.action();
        state = States.Disarming;
      }
    }
    else if (state == States.Disarming)
    {
      assert(false);
    }
    else if (state == States.Triggered)
    {
      {
        sensor.in.disable.action();
        siren.in.turnoff.action();
        sounding = false;
        state = States.Disarming;
      }
    }
  }

  public void sensor_triggered()
  {
    System.err.println("Alarm.sensor_triggered");
    if (state == States.Disarmed)
    {
      assert(false);
    }
    else if (state == States.Armed)
    {
      {
        console.out.detected.action();
        siren.in.turnon.action();
        sounding = true;
        state = States.Triggered;
      }
    }
    else if (state == States.Disarming)
    {
      {
      }
    }
    else if (state == States.Triggered)
    {
      assert(false);
    }
  }

  public void sensor_disabled()
  {
    System.err.println("Alarm.sensor_disabled");
    if (state == States.Disarmed)
    {
      assert(false);
    }
    else if (state == States.Armed)
    {
      assert(false);
    }
    else if (state == States.Disarming)
    {
      {
        if (sounding)
        {
          console.out.deactivated.action();
          siren.in.turnoff.action();
          state = States.Disarmed;
          sounding = false;
        }
        else
        {
          console.out.deactivated.action();
          state = States.Disarmed;
        }
      }
    }
    else if (state == States.Triggered)
    {
      assert(false);
    }
  }

}


// Handwritten
class Console
{
  IConsole console;
  public Console()
  {
    console = new IConsole();
    console.out.detected = new Action()
      {
        public void action()
        {
          System.err.println("Alarm detected");
        }
      };
    console.out.deactivated = new Action()
      {
        public void action()
        {
          System.err.println("Alarm deactivated");
        }
      };
  }
}

class Sensor
{
  ISensor sensor;
  public Sensor()
  {
    sensor = new ISensor();
    sensor.in.enable = new Action()
      {
        public void action()
        {
          System.err.println("Sensor detected");
        }
      };
    sensor.in.disable = new Action()
      {
        public void action()
        {
          System.err.println("Sensor deactivated");
        }
      };
  }
}

class Siren
{
  ISiren siren;
  public Siren()
  {
    siren = new ISiren();
    siren.in.turnon = new Action()
      {
        public void action()
        {
          System.err.println("Siren detected");
        }
      };
    siren.in.turnoff = new Action()
      {
        public void action()
        {
          System.err.println("Siren deactivated");
        }
      };
  }
}

class alarm
{
  public static void main(String[] args)
  {
    System.err.println("alarm main");
    AlarmSystem alarm = new AlarmSystem();
    Console console = new Console();
    Interface.connect(alarm.console, console.console);

    // Test trace

    alarm.console.in.arm.action();
    alarm.alarm.sensor.out.triggered.action();
    alarm.console.in.disarm.action();
    alarm.alarm.sensor.out.disabled.action();
  }
}
