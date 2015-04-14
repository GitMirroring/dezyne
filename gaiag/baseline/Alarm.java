// Dezyne --- Dezyne command line tools
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

class Alarm extends Component {
  enum States {
    Disarmed, Armed, Triggered, Disarming
  };

  States state;
  Boolean sounding;

  IConsole console;
  ISensor sensor;
  ISiren siren;

  public Alarm(Runtime runtime) {this(runtime, "");};

  public Alarm(Runtime runtime, String name) {this(runtime, name, null);};

  public Alarm(Runtime runtime, String name, SystemComponent parent) {
    super(runtime, name, parent);
    this.flushes = true;
    state = States.Disarmed;
    sounding = false;
    console = new IConsole();
    console.in.name = "console";
    console.in.self = this;
    state = States.Disarmed;
    sounding = false;
    sensor = new ISensor();
    sensor.out.name = "sensor";
    sensor.out.self = this;
    siren = new ISiren();
    siren.out.name = "siren";
    siren.out.self = this;
    console.in.arm = new Action() {public void action() {Runtime.callIn(Alarm.this, new Action() {public void action() {console_arm();}}, new Meta(Alarm.this.console, "arm"));};};

    console.in.disarm = new Action() {public void action() {Runtime.callIn(Alarm.this, new Action() {public void action() {console_disarm();}}, new Meta(Alarm.this.console, "disarm"));};};

    sensor.out.triggered = new Action() {public void action() {Runtime.callOut(Alarm.this, new Action() {public void action() {sensor_triggered();}}, new Meta(Alarm.this.sensor, "triggered"));};};

    sensor.out.disabled = new Action() {public void action() {Runtime.callOut(Alarm.this, new Action() {public void action() {sensor_disabled();}}, new Meta(Alarm.this.sensor, "disabled"));};};

  };
  public void console_arm() {
    if (state == States.Disarmed) {
      {
        sensor.in.enable.action();
        state = States.Armed;
      }
    }
    else if (state == States.Armed) {
      throw new RuntimeException("illegal");
    }
    else if (state == States.Disarming) {
      throw new RuntimeException("illegal");
    }
    else if (state == States.Triggered) {
      throw new RuntimeException("illegal");
    }
  };

  public void console_disarm() {
    if (state == States.Disarmed) {
      throw new RuntimeException("illegal");
    }
    else if (state == States.Armed) {
      {
        sensor.in.disable.action();
        state = States.Disarming;
      }
    }
    else if (state == States.Disarming) {
      throw new RuntimeException("illegal");
    }
    else if (state == States.Triggered) {
      {
        sensor.in.disable.action();
        siren.in.turnoff.action();
        sounding = false;
        state = States.Disarming;
      }
    }
  };

  public void sensor_triggered() {
    if (state == States.Disarmed) {
      throw new RuntimeException("illegal");
    }
    else if (state == States.Armed) {
      {
        console.out.detected.action();
        siren.in.turnon.action();
        sounding = true;
        state = States.Triggered;
      }
    }
    else if (state == States.Disarming) {
      { }
    }
    else if (state == States.Triggered) {
      throw new RuntimeException("illegal");
    }
  };

  public void sensor_disabled() {
    if (state == States.Disarmed) {
      throw new RuntimeException("illegal");
    }
    else if (state == States.Armed) {
      throw new RuntimeException("illegal");
    }
    else if (state == States.Disarming && sounding) {
      console.out.deactivated.action();
      siren.in.turnoff.action();
      state = States.Disarmed;
      sounding = false;
    }
    else if (state == States.Disarming && ! (sounding)) {
      console.out.deactivated.action();
      state = States.Disarmed;
    }
    else if (state == States.Triggered) {
      throw new RuntimeException("illegal");
    }
  };

}
