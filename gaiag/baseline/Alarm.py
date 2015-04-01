# Dezyne --- Dezyne command line tools
#
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Dezyne.
#
# Dezyne is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Dezyne is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

import dezyne.IConsole
import dezyne.ISensor
import dezyne.ISiren

import runtime

class Alarm:
    class States ():
        Disarmed, Armed, Triggered, Disarming = range (4)

    def __init__ (self, rt, parent=None, name=''):
        self.rt = rt
        rt.components += [self]
        self.parent = parent
        self.name = name
        self.handling = False
        self.flushes = True
        self.deferred = None
        self.queue = []

        self.state = self.States.Disarmed
        self.sounding = False

        self.console = dezyne.IConsole (provides=('console', self))

        self.sensor = dezyne.ISensor (requires=('sensor', self))
        self.siren = dezyne.ISiren (requires=('siren', self))

        self.console.ins.arm = lambda *args: runtime.call_in (self, lambda: self.console_arm (*args), (self.console, 'arm'))
        self.console.ins.disarm = lambda *args: runtime.call_in (self, lambda: self.console_disarm (*args), (self.console, 'disarm'))
        self.sensor.outs.triggered = lambda *args: runtime.call_out (self, lambda: self.sensor_triggered (*args), (self.sensor, 'triggered'))
        self.sensor.outs.disabled = lambda *args: runtime.call_out (self, lambda: self.sensor_disabled (*args), (self.sensor, 'disabled'))

    def console_arm (self):
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
        if (self.state == self.States.Disarmed):
            assert (False)
        elif (self.state == self.States.Armed):
            assert (False)
        elif (self.state == self.States.Disarming and self.sounding):
            self.console.outs.deactivated ()
            self.siren.ins.turnoff ()
            self.state = self.States.Disarmed
            self.sounding = False
        elif (self.state == self.States.Disarming and not (self.sounding)):
            self.console.outs.deactivated ()
            self.state = self.States.Disarmed
        elif (self.state == self.States.Triggered):
            assert (False)



