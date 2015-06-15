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


/* handwritten alarm.js */

// dezyne.Console = function(rt, meta) {
//   this.rt = rt;
//   this.meta = meta;
//   this.console = new dezyne.IConsole({provides: {}, requires: {component: this, name: 'console'}});
//   this.console.out.detected = function() {process.stderr.write('Console.detected\n');}
//   this.console.out.deactivated = function() {process.stderr.write('Console.deactivated\n');}
// };

// dezyne.Sensor = function(rt, meta) {
//   this.rt = rt;
//   this.meta = meta;
//   this.sensor = new dezyne.ISensor({provides: {component: this, name: 'sensor'}, requires: {}});
//   this.sensor.in.enable = function() {runtime.call_in(this, function() {}, [this.sensor, 'enable']);}.bind(this);
//   this.sensor.in.disable = function() {runtime.call_in(this, function() {}, [this.sensor, 'disable']);}.bind(this);
// }

// dezyne.Siren = function(rt, meta) {
//   this.rt = rt;
//   this.meta = meta;
//   this.siren = new dezyne.ISiren({provides: {component: this, name: 'siren'}, requires: {}});
//   this.siren.in.turnon = function() {runtime.call_in(this, function() {}, [this.siren, 'turnon']); }.bind(this);
//   this.siren.in.turnoff = function() {runtime.call_in(this, function() {}, [this.siren, 'turnoff']); }.bind(this);
// }

function main() {
  var loc = new dezyne.locator();
  var rt = new dezyne.runtime();
  var sut = new dezyne.AlarmSystem(loc.set(rt), {name: 'sut'});
  // var gui = new dezyne.Console(rt, {});// {name: 'sut'});
  // dezyne.connect(sut.console, gui.console);

  sut.console.out.detected = function () {console.error('Console.detected');}
  sut.console.out.deactivated = function () {console.error('Console.deactivated');}
  sut.console.in.arm();
  sut.sensor.sensor.out.triggered();
  rt.flush(sut.sensor);
  sut.console.in.disarm();
  sut.sensor.sensor.out.disabled();
  rt.flush(sut.sensor);
}

main();
