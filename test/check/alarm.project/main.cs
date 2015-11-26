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

// -*-java-*-
using System;
using System.Diagnostics;

class main {
  public static void Main(String[] args) {
    Locator locator = new Locator();
    Runtime runtime = new Runtime();
    AlarmSystem sut = new AlarmSystem(locator.set(runtime), "sut");
    sut.console.outport.detected = () => {System.Console.Error.WriteLine("Console.detected");};
    sut.console.outport.deactivated = () => {System.Console.Error.WriteLine("Console.deactivated");};
    // Test trace

    sut.console.inport.arm();
    sut.sensor.sensor.outport.triggered();
    Runtime.flush(sut.sensor);
    sut.console.inport.disarm();
    sut.sensor.sensor.outport.disabled();
    Runtime.flush(sut.sensor);
  }
}
