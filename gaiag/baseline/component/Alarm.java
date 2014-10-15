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
    console = new IConsole();
    sensor = new ISensor();
    siren = new ISiren();
    console.getIn().arm = new Action() {
      public void action() {
        console_arm() ;
      }
    } ;
    console.getIn().disarm = new Action() {
      public void action() {
        console_disarm() ;
      }
    } ;
    sensor.getOut().triggered = new Action() {
      public void action() {
        sensor_triggered() ;
      }
    } ;
    sensor.getOut().disabled = new Action() {
      public void action() {
        sensor_disabled() ;
      }
    } ;
    public void console_arm() {
      System.err.println("Alarm.console_arm");
      if (state == States.Disarmed) {
        {
          sensor.getIn().enable();
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
          sensor.getIn().disable();
          state = States.Disarming;
        }
      }
      else if (state == States.Disarming) {
        assert(false);
      }
      else if (state == States.Triggered) {
        {
          sensor.getIn().disable();
          siren.getIn().turnoff();
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
          console.getOut().detected();
          siren.getIn().turnon();
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
            console.getOut().deactivated();
            siren.getIn().turnoff();
            state = States.Disarmed;
            sounding = false;
          }
          else {
            console.getOut().deactivated();
            state = States.Disarmed;
          }
        }
      }
      else if (state == States.Triggered) {
        assert(false);
      }
    };

  };
}
