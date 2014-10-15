// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

component.Alarm = function() {
  this.States= {
    Disarmed: 0, Armed: 1, Triggered: 2, Disarming: 3
  };

  this.state = this.States.Disarmed;
  this.sounding = false;

  this.console = new interface.IConsole();
  this.sensor = new interface.ISensor();
  this.siren = new interface.ISiren();

  this.console.in.arm = function() {
    console.log('Alarm.console_arm');
    if(this.state === this.States.Disarmed) {
      {
        this.sensor.in.enable();
        this.state = this.States.Armed;
      }
    }
    else if(this.state === this.States.Armed) {
      assert (false);
    }
    else if(this.state === this.States.Disarming) {
      assert (false);
    }
    else if(this.state === this.States.Triggered) {
      assert (false);
    }
  }.bind(this);
  this.console.in.disarm = function() {
    console.log('Alarm.console_disarm');
    if(this.state === this.States.Disarmed) {
      assert (false);
    }
    else if(this.state === this.States.Armed) {
      {
        this.sensor.in.disable();
        this.state = this.States.Disarming;
      }
    }
    else if(this.state === this.States.Disarming) {
      assert (false);
    }
    else if(this.state === this.States.Triggered) {
      {
        this.sensor.in.disable();
        this.siren.in.turnoff();
        this.sounding = false;
        this.state = this.States.Disarming;
      }
    }
  }.bind(this);
  this.sensor.out.triggered = function() {
    console.log('Alarm.sensor_triggered');
    if(this.state === this.States.Disarmed) {
      assert (false);
    }
    else if(this.state === this.States.Armed) {
      {
        this.console.out.detected();
        this.siren.in.turnon();
        this.sounding = true;
        this.state = this.States.Triggered;
      }
    }
    else if(this.state === this.States.Disarming) {
      { }
    }
    else if(this.state === this.States.Triggered) {
      assert (false);
    }
  }.bind(this);
  this.sensor.out.disabled = function() {
    console.log('Alarm.sensor_disabled');
    if(this.state === this.States.Disarmed) {
      assert (false);
    }
    else if(this.state === this.States.Armed) {
      assert (false);
    }
    else if(this.state === this.States.Disarming) {
      {
        if(this.sounding) {
          this.console.out.deactivated();
          this.siren.in.turnoff();
          this.state = this.States.Disarmed;
          this.sounding = false;
        }
        else {
          this.console.out.deactivated();
          this.state = this.States.Disarmed;
        }
      }
    }
    else if(this.state === this.States.Triggered) {
      assert (false);
    }
  }.bind(this);

};
