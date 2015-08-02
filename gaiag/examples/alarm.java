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

// Handwritten
class Console extends Component {
  IConsole console;
  public Console(Locator locator, String name, SystemComponent parent) {
    super(locator, name, parent);
    console = new IConsole();
    console.out.detected = new Action() {
        public void action() {
          System.err.println("Alarm detected");
        }
      };
    console.out.deactivated = new Action() {
        public void action() {
          System.err.println("Alarm deactivated");
        }
      };
  }
}

class Sensor extends Component {
  ISensor sensor;
  public Sensor(Locator locator, String name, SystemComponent parent) {
    super(locator, name, parent);
    sensor = new ISensor();
    sensor.in.enable = new Action() {
        public void action() {
          System.err.println("Sensor detected");
        }
      };
    sensor.in.disable = new Action() {
        public void action() {
          System.err.println("Sensor deactivated");
        }
      };
  }
}

class Siren extends Component {
  ISiren siren;
  public Siren(Locator locator, String name, SystemComponent parent) {
    super(locator, name, parent);
    siren = new ISiren();
    siren.in.turnon = new Action() {
        public void action() {
          System.err.println("Siren detected");
        }
      };
    siren.in.turnoff = new Action() {
        public void action() {
          System.err.println("Siren deactivated");
        }
      };
  }
}

class alarm {
  public static void main(String[] args) {
    Locator locator = new Locator();
    Runtime runtime = new Runtime();
    AlarmSystem sut = new AlarmSystem(locator.set(runtime), "sut");
    //Console console = new Console(runtime, "", null);
    //Interface.connect(sut.console, console.console);
    sut.console.out.detected = new Action() {public void action() {System.err.println("Console.detected");}};
    sut.console.out.deactivated = new Action() {public void action() {System.err.println("Console.deactivated");}};

    // Test trace

    sut.console.in.arm.action();
    sut.sensor.sensor.out.triggered.action();
    Runtime.flush(sut.sensor);
    sut.console.in.disarm.action();
    sut.sensor.sensor.out.disabled.action();
    Runtime.flush(sut.sensor);
  }
}
