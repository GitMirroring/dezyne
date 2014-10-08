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

component.Alarm = function() {
  this.States= {
    Disarmed: 0, Armed: 1, Triggered: 2, Disarming: 3
  };

  this.state = this.States.Disarmed;
  this.sounding = false;

  this.console = new interface.Console();
  this.sensor = new interface.Sensor();
  this.siren = new interface.Siren();

  this.console.ins.arm = function() {
    console.log('Alarm.console_arm');
    if(this.state == this.States.Disarmed) {
      {
        this.sensor.ins.enable();
        this.state = this.States.Armed;
      }
    }

    else if (this.state == this.States.Armed) {
      assert (false);
    }

    else if (this.state == this.States.Disarming) {
      assert (false);
    }

    else if (this.state == this.States.Triggered) {
      assert (false);
    }

  }.bind(this);

  this.console.ins.disarm = function() {
    console.log('Alarm.console_disarm');
    if(this.state == this.States.Disarmed) {
      assert (false);
    }

    else if (this.state == this.States.Armed) {
      {
        this.sensor.ins.disable();
        this.state = this.States.Disarming;
      }
    }

    else if (this.state == this.States.Disarming) {
      assert (false);
    }

    else if (this.state == this.States.Triggered) {
      {
        this.sensor.ins.disable();
        this.siren.ins.turnoff();
        this.sounding = false;
        this.state = this.States.Disarming;
      }
    }

  }.bind(this);

  this.sensor.outs.triggered = function() {
    console.log('Alarm.sensor_triggered');
    if(this.state == this.States.Disarmed) {
      assert (false);
    }

    else if (this.state == this.States.Armed) {
      {
        this.console.outs.detected();
        this.siren.ins.turnon();
        this.sounding = true;
        this.state = this.States.Triggered;
      }
    }

    else if (this.state == this.States.Disarming) {
      { }
    }

    else if (this.state == this.States.Triggered) {
      assert (false);
    }

  }.bind(this);

  this.sensor.outs.disabled = function() {
    console.log('Alarm.sensor_disabled');
    if(this.state == this.States.Disarmed) {
      assert (false);
    }

    else if (this.state == this.States.Armed) {
      assert (false);
    }

    else if (this.state == this.States.Disarming) {
      {
        if(this.sounding) {
          this.console.outs.deactivated();
          this.siren.ins.turnoff();
          this.state = this.States.Disarmed;
          this.sounding = false;
        }

        else {
          this.console.outs.deactivated();
          this.state = this.States.Disarmed;
        }

      }
    }

    else if (this.state == this.States.Triggered) {
      assert (false);
    }

  }.bind(this);


};
