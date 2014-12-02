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

#! /usr/bin/nodejs

// handwritten runtime header
var dezyne = {};

Function.prototype.defer = function ()
{
  setTimeout (this, 0.01);
};

dezyne.connect = function (provided, required) {
  provided.out = required.out;
  required.in = provided.in;
}
// end header
dezyne.ISiren = function() {
  this.in = {
    turnon : null,
    turnoff : null
  };
  this.out = {

  };
};
dezyne.AlarmSystem = function() {
  this.alarm = new dezyne.Alarm();
  this.sensor = new dezyne.Sensor();
  this.siren = new dezyne.Siren();
  this.console = this.alarm.console;

  dezyne.connect(this.sensor.sensor, this.alarm.sensor);
  dezyne.connect(this.siren.siren, this.alarm.siren);

};
dezyne.IConsole = function() {
  this.in = {
    arm : null,
    disarm : null
  };
  this.out = {
    detected : null,
    deactivated : null
  };
};
dezyne.ISensor = function() {
  this.in = {
    enable : null,
    disable : null
  };
  this.out = {
    triggered : null,
    disabled : null
  };
};
dezyne.Alarm = function() {
  this.States = {
    Disarmed: 0, Armed: 1, Triggered: 2, Disarming: 3
  };
  this.state = this.States.Disarmed;
  this.sounding = false;

  this.console = new dezyne.IConsole();
  this.sensor = new dezyne.ISensor();
  this.siren = new dezyne.ISiren();

  this.console.in.arm = function() {
    console.log('Alarm.console_arm');
    if(this.state === this.States.Disarmed) {
      this.sensor.in.enable();
      this.state = this.States.Armed;
    }
    else if(this.state === this.States.Armed) {
      console.assert (false);
    }
    else if(this.state === this.States.Disarming) {
      console.assert (false);
    }
    else if(this.state === this.States.Triggered) {
      console.assert (false);
    }
  }.bind(this);
  this.console.in.disarm = function() {
    console.log('Alarm.console_disarm');
    if(this.state === this.States.Disarmed) {
      console.assert (false);
    }
    else if(this.state === this.States.Armed) {
      this.sensor.in.disable();
      this.state = this.States.Disarming;
    }
    else if(this.state === this.States.Disarming) {
      console.assert (false);
    }
    else if(this.state === this.States.Triggered) {
      this.sensor.in.disable();
      this.siren.in.turnoff();
      this.sounding = false;
      this.state = this.States.Disarming;
    }
  }.bind(this);
  this.sensor.out.triggered = function() {
    console.log('Alarm.sensor_triggered');
    if(this.state === this.States.Disarmed) {
      console.assert (false);
    }
    else if(this.state === this.States.Armed) {
      this.console.out.detected.defer();
      this.siren.in.turnon();
      this.sounding = true;
      this.state = this.States.Triggered;
    }
    else if(this.state === this.States.Disarming) {
      { }
    }
    else if(this.state === this.States.Triggered) {
      console.assert (false);
    }
  }.bind(this);
  this.sensor.out.disabled = function() {
    console.log('Alarm.sensor_disabled');
    if(this.state === this.States.Disarmed) {
      console.assert (false);
    }
    else if(this.state === this.States.Armed) {
      console.assert (false);
    }
    else if(this.state === this.States.Disarming) {
      if(this.sounding) {
        this.console.out.deactivated.defer();
        this.siren.in.turnoff();
        this.state = this.States.Disarmed;
        this.sounding = false;
      }
      else {
        this.console.out.deactivated.defer();
        this.state = this.States.Disarmed;
      }
    }
    else if(this.state === this.States.Triggered) {
      console.assert (false);
    }
  }.bind(this);

};
/* main */
///// Test stubs
dezyne.Console = function() {
  this.console = new dezyne.IConsole();
  this.console.out.detected = function() { console.log('Alarm detected'); }
  this.console.out.deactivated = function() { console.log('Alarm deactivated'); }
};
dezyne.Sensor = function() {
  this.sensor = new dezyne.ISensor();
  this.sensor.in.enable = function() { console.log('Sensor enable')};
  this.sensor.in.disable = function() { console.log('Sensor disable');};
}
dezyne.Siren = function() {
  this.siren = new dezyne.ISiren();
  this.siren.in.turnon = function() { console.log('Siren turnon'); };
  this.siren.in.turnoff = function() { console.log('Siren turnoff'); };
}

var alarm = new dezyne.AlarmSystem();
var gui = new dezyne.Console();
dezyne.connect(alarm.console, gui.console);
///// Test trace
alarm.console.in.arm();
alarm.sensor.sensor.out.triggered();
alarm.console.in.disarm();
alarm.sensor.sensor.out.disabled();
