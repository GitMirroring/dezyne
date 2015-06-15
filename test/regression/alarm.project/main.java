// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

// // Handwritten
// class Console {
//   IConsole console;
//   public Console() {
//     console = new IConsole();
//     console.getOut().detected = new Action() {
//         public void action() {
//           System.err.println("Alarm detected");
//         }
//       };
//     console.getOut().deactivated = new Action() {
//         public void action() {
//           System.err.println("Alarm deactivated");
//         }
//       };
//   }
// }

// class Sensor {
//   ISensor sensor;
//   public Sensor() {
//     sensor = new ISensor();
//     sensor.getIn().enable = new Action() {
//         public void action() {
//           System.err.println("Sensor detected");
//         }
//       };
//     sensor.getIn().disable = new Action() {
//         public void action() {
//           System.err.println("Sensor deactivated");
//         }
//       };
//   }
// }

// class Siren {
//   ISiren siren;
//   public Siren() {
//     siren = new ISiren();
//     siren.getIn().turnon = new Action() {
//         public void action() {
//           System.err.println("Siren detected");
//         }
//       };
//     siren.getIn().turnoff = new Action() {
//         public void action() {
//           System.err.println("Siren deactivated");
//         }
//       };
//   }
// }

class main {
  public static void main(String[] args) {
    Locator locator = new Locator();
    Runtime runtime = new Runtime();
    AlarmSystem sut = new AlarmSystem(locator.set(runtime), "sut");
    //Console console = new Console();
    //Interface.connect(sut.console, console.console);
    sut.console.out.detected = () -> {System.err.println("Console.detected");};
    sut.console.out.deactivated = () -> {System.err.println("Console.deactivated");};
    // Test trace

    sut.console.in.arm.action();
    sut.sensor.sensor.out.triggered.action();
    Runtime.flush(sut.sensor);
    sut.console.in.disarm.action();
    sut.sensor.sensor.out.disabled.action();
    Runtime.flush(sut.sensor);
  }
}
