# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Gaiag.
#
# Gaiag is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Gaiag is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

import inspect
import sys
try:
    from enum import Enum
except:
    class Enum (): pass
#
import interface.Console
import interface.Sensor
import interface.Siren


class Alarm ():
    class States (Enum):
        Disarmed, Armed, Triggered, Disarming = range (4)

    def __init__ (self):
        self.state = self.States.Disarmed
        self.sounding = False

        self.console = interface.Console ()
        self.sensor = interface.Sensor ()
        self.siren = interface.Siren ()

        self.console.ins.arm = self.console_arm
        self.console.ins.disarm = self.console_disarm
        self.sensor.outs.triggered = self.sensor_triggered
        self.sensor.outs.disabled = self.sensor_disabled

    def console_arm (self):
        sys.stderr.write ('Alarm.console_arm\n')
        if (self.state == self.States.Disarmed):
            self.sensor.ins.enable ()
            self.state = self.States.Armed
        elif (self.state == self.States.Armed):
            assert (False)
        elif (self.state == self.States.Disarming):
            assert (False)
        elif (self.state == self.States.Triggered):
            assert (False)

    def console_disarm (self):
        sys.stderr.write ('Alarm.console_disarm\n')
        if (self.state == self.States.Disarmed):
            assert (False)
        elif (self.state == self.States.Armed):
            self.sensor.ins.disable ()
            self.state = self.States.Disarming
        elif (self.state == self.States.Disarming):
            assert (False)
        elif (self.state == self.States.Triggered):
            self.sensor.ins.disable ()
            self.siren.ins.turnoff ()
            self.sounding = False
            self.state = self.States.Disarming

    def sensor_triggered (self):
        sys.stderr.write ('Alarm.sensor_triggered\n')
        if (self.state == self.States.Disarmed):
            assert (False)
        elif (self.state == self.States.Armed):
            self.console.outs.detected ()
            self.siren.ins.turnon ()
            self.sounding = True
            self.state = self.States.Triggered
        elif (self.state == self.States.Disarming):
            pass
        elif (self.state == self.States.Triggered):
            assert (False)

    def sensor_disabled (self):
        sys.stderr.write ('Alarm.sensor_disabled\n')
        if (self.state == self.States.Disarmed):
            assert (False)
        elif (self.state == self.States.Armed):
            assert (False)
        elif (self.state == self.States.Disarming):
            if (self.sounding):
                self.console.outs.deactivated ()
                self.siren.ins.turnoff ()
                self.state = self.States.Disarmed
                self.sounding = False
            else:
                self.console.outs.deactivated ()
                self.state = self.States.Disarmed
        elif (self.state == self.States.Triggered):
            assert (False)


