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

#! /usr/bin/env node
var interface = {};
var component = {};
function connect(provided, required) {
  provided.out = required.out;
  required.in = provided.in;
}
interface.Console = function() {
  this.in = {
    arm: null,
    disarm: null
  };
  this.out = {
    detected: null,
    deactivated: null
  };
};
interface.Siren = function() {
  this.in = {
    turnon: null,
    turnoff: null
  };
  this.out = {
  };
};
interface.Sensor = function() {
  this.in = {
    enable: null,
    disable: null
  };
  this.out = {
    triggered: null,
    disabled: null
  };
};
component.AlarmSystem = function() {
  this.sensor = new component.Sensor();
  this.siren = new component.Siren();
  this.alarm = new component.Alarm();
  this.console = this.alarm.console;
 connect(this.sensor.sensor, this.alarm.sensor);
  connect(this.siren.siren, this.alarm.siren);
}
component.Alarm = function() {
    this.States = {
        Disarmed: 0, Armed: 1, Triggered: 2, Disarming: 3
    };
    this.state = this.States.Disarmed;
    this.sounding = false;
    this.console = new interface.Console();
    this.sensor = new interface.Sensor();
    this.siren = new interface.Siren();
    this.console.in.arm  = function() {
        console.log('Alarm.console_arm');
        if(this.state == this.States.Disarmed) {
            this.sensor.in.enable();
            this.state = this.States.Armed;
        }
        else if (this.state == this.States.Armed) {
            assert(false);
        }
        else if (this.state == this.States.Disarming) {
            assert(false);
        }
        else if (this.state == this.States.Triggered) {
            assert(false);
        }
    }.bind(this);
    this.console.in.disarm = function() {
        console.log('Alarm.console_disarm');
        if(this.state == this.States.Disarmed) {
            assert(false);
        }
        else if (this.state == this.States.Armed) {
            this.sensor.in.disable();
            this.state = this.States.Disarming;
        }
        else if (this.state == this.States.Disarming) {
            assert(false);
        }
        else if (this.state == this.States.Triggered) {
            this.sensor.in.disable();
            this.sounding = false;
            this.state = this.States.Disarming;
        }
    }.bind(this);
    this.sensor.out.triggered = function() {
        console.log('Alarm.sensor_triggered');
        if(this.state == this.States.Disarmed) {
            assert(false);
        }
        else if (this.state == this.States.Armed) {
            this.console.out.detected();
            this.siren.in.turnon();
            this.sounding = true;
            this.state = this.States.Triggered;
        }
        else if (this.state == this.States.Disarming) {
            assert(false);
        }
        else if (this.state == this.States.Triggered) {
            assert(false);
        }
    }.bind(this);
    this.sensor.out.disabled = function() {
        console.log('Alarm.sensor_disabled')
        if(this.state == this.States.Disarmed) {
            assert(false)
        }
        else if (this.state == this.States.Armed) {
            assert(false);
        }
        else if (this.state == this.States.Disarming) {
            if(this.sounding) {
                this.console.out.deactivated();
                this.sounding = false;
                this.state = this.States.Disarmed;
            }
            else {
                this.console.out.deactivated();
                this.state = this.States.Disarmed;
            }
        }
        else if (this.state == this.States.Triggered) {
            assert(false);
        }
    }.bind(this);
}
///// Test stubs
component.Console = function() {
  this.console = new interface.Console();
  this.console.out.detected = function() { console.log('Alarm detected'); }
  this.console.out.deactivated = function() { console.log('Alarm deactivated'); }
};
component.Sensor = function() {
  this.sensor = new interface.Sensor();
  this.sensor.in.enable = function() { console.log('Sensor enabled')};
  this.sensor.in.disable = function() { console.log('Sensor disabled');};
}
component.Siren = function() {
  this.siren = new interface.Siren();
  this.siren.in.turnon = function() { console.log('Siren on'); };
  this.siren.in.turnoff = function() { console.log('Siren off'); };
}

var alarm = new component.AlarmSystem();
var gui = new component.Console();
connect(alarm.console, gui.console);
///// Test trace
alarm.console.in.arm();
alarm.sensor.sensor.out.triggered();
alarm.console.in.disarm();
alarm.sensor.sensor.out.disabled();
