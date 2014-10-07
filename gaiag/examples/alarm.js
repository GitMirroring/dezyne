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

/* main */
///// Test stubs
component.Console = function() {
  this.console = new interface.Console();
  this.console.outs.detected = function() { console.log('Alarm detected'); }
  this.console.outs.deactivated = function() { console.log('Alarm deactivated'); }
};
component.Sensor = function() {
  this.sensor = new interface.Sensor();
  this.sensor.ins.enable = function() { console.log('Sensor enabled')};
  this.sensor.ins.disable = function() { console.log('Sensor disabled');};
}
component.Siren = function() {
  this.siren = new interface.Siren();
  this.siren.ins.turnon = function() { console.log('Siren on'); };
  this.siren.ins.turnoff = function() { console.log('Siren off'); };
}

var alarm = new component.AlarmSystem();
var gui = new component.Console();
connect(alarm.console, gui.console);
///// Test trace
alarm.console.ins.arm();
alarm.sensor.sensor.outs.triggered();
alarm.console.ins.disarm();
alarm.sensor.sensor.outs.disabled();
