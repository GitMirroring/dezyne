// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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


/* handwritten alarm.js */

dezyne.Console = function() {
  this.console = new dezyne.IConsole();
  this.console.out.detected = function() { console.log('Console.detected'); }
  this.console.out.deactivated = function() { console.log('Console.deactivated'); }
};

dezyne.Sensor = function() {
  this.sensor = new dezyne.ISensor();
  this.sensor.in.enable = function() { console.log('Sensor.sensor_enable')};
  this.sensor.in.disable = function() { console.log('Sensor.sensor_disable');};
}

dezyne.Siren = function() {
  this.siren = new dezyne.ISiren();
  this.siren.in.turnon = function() { console.log('Siren.siren_turnon'); };
  this.siren.in.turnoff = function() { console.log('Siren.siren_turnoff'); };
}

function main() {
  var alarm = new dezyne.AlarmSystem();
  var gui = new dezyne.Console();
  dezyne.connect(alarm.console, gui.console);

  alarm.console.in.arm();
  alarm.sensor.sensor.out.triggered();
  alarm.console.in.disarm();
  alarm.sensor.sensor.out.disabled();
}

main();
