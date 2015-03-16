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

dezyne.Console = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.console = new dezyne.IConsole({provides: this, requires: this});
  this.console.out.detected = function() {process.stderr.write('Console.detected\n');}
  this.console.out.deactivated = function() {process.stderr.write('Console.deactivated\n');}
};

dezyne.Sensor = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.sensor = new dezyne.ISensor({provides: this, requires: this});
  this.sensor.in.enable = function() {runtime.call_in(this, function() {}, [this.sensor, 'sensor', 'enable']);}.bind(this);
  this.sensor.in.disable = function() {runtime.call_in(this, function() {}, [this.sensor, 'sensor', 'disable']);}.bind(this);
}

dezyne.Siren = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.siren = new dezyne.ISiren({provides: this, requires: this});
  this.siren.in.turnon = function() {runtime.call_in(this, function() {}, [this.siren, 'siren', 'turnon']); }.bind(this);
  this.siren.in.turnoff = function() {runtime.call_in(this, function() {}, [this.siren, 'siren', 'turnoff']); }.bind(this);
}

function main() {
  var rt = new dezyne.runtime();
  var alarmsystem = new dezyne.AlarmSystem(rt, {name: 'alarmsystem'});
  var gui = new dezyne.Console(rt, {name: 'alarmsystem'});
  dezyne.connect(alarmsystem.console, gui.console);

  alarmsystem.console.in.arm();
  alarmsystem.sensor.sensor.out.triggered();
  alarmsystem.console.in.disarm();
  alarmsystem.sensor.sensor.out.disabled();
}

main();
